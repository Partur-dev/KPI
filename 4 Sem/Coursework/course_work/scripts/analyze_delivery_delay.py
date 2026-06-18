import json
import sqlite3
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import HistGradientBoostingClassifier, RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    average_precision_score,
    balanced_accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    precision_recall_curve,
    recall_score,
    roc_auc_score,
)
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.tree import DecisionTreeClassifier


ROOT = Path(__file__).resolve().parents[2]
DB_PATH = ROOT / "lab_olist_warehouse" / "output" / "olist_dw.sqlite"
OUT_DIR = ROOT / "course_work" / "assets"
REPORT_TABLES_PATH = OUT_DIR / "model_metrics.csv"
DATASET_PATH = OUT_DIR / "delivery_delay_dataset.csv"
SUMMARY_PATH = OUT_DIR / "analysis_summary.json"

RANDOM_STATE = 42


def haversine_km(lat1: pd.Series, lon1: pd.Series, lat2: pd.Series, lon2: pd.Series) -> pd.Series:
    radius_km = 6371.0
    lat1_rad = np.radians(lat1.astype(float))
    lon1_rad = np.radians(lon1.astype(float))
    lat2_rad = np.radians(lat2.astype(float))
    lon2_rad = np.radians(lon2.astype(float))
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    a = np.sin(dlat / 2) ** 2 + np.cos(lat1_rad) * np.cos(lat2_rad) * np.sin(dlon / 2) ** 2
    c = 2 * np.arcsin(np.sqrt(a))
    return radius_km * c


def load_dataset() -> pd.DataFrame:
    query = """
    WITH payment_agg AS (
        SELECT
            p.order_id,
            SUM(p.payment_value) AS payment_value,
            AVG(p.payment_installments) AS payment_installments,
            COUNT(*) AS payment_count,
            GROUP_CONCAT(DISTINCT pt.payment_type) AS payment_types
        FROM fact_payments p
        LEFT JOIN dim_payment_type pt ON pt.payment_type_key = p.payment_type_key
        GROUP BY p.order_id
    ),
    item_agg AS (
        SELECT
            f.order_id,
            COUNT(*) AS order_items_count,
            SUM(f.price) AS order_price_sum,
            SUM(f.freight_value) AS freight_sum,
            SUM(f.total_item_value) AS total_item_value_sum,
            AVG(f.price) AS item_price_avg,
            AVG(f.freight_value) AS freight_avg,
            AVG(prod.product_weight_g) AS product_weight_g_avg,
            AVG(prod.product_length_cm) AS product_length_cm_avg,
            AVG(prod.product_height_cm) AS product_height_cm_avg,
            AVG(prod.product_width_cm) AS product_width_cm_avg,
            AVG(prod.product_name_length) AS product_name_length_avg,
            AVG(prod.product_description_length) AS product_description_length_avg,
            AVG(prod.product_photos_qty) AS product_photos_qty_avg,
            MIN(COALESCE(cat.category_name_english, 'unknown')) AS primary_category,
            MIN(cust_loc.state) AS customer_state,
            MIN(cust_loc.city) AS customer_city,
            MIN(cust_loc.avg_lat) AS customer_lat,
            MIN(cust_loc.avg_lng) AS customer_lng,
            MIN(seller_loc.state) AS seller_state,
            MIN(seller_loc.city) AS seller_city,
            MIN(seller_loc.avg_lat) AS seller_lat,
            MIN(seller_loc.avg_lng) AS seller_lng,
            MIN(date_dim.year) AS purchase_year,
            MIN(date_dim.month) AS purchase_month,
            MIN(date_dim.day_of_week) AS purchase_day_of_week,
            MIN(date_dim.week_of_year) AS purchase_week_of_year,
            MIN(date_dim.full_date) AS purchase_date,
            MIN(ord.order_purchase_timestamp) AS purchase_timestamp,
            MIN(ord.order_approved_at) AS approved_timestamp,
            MIN(ord.order_estimated_delivery_date) AS estimated_delivery_timestamp,
            MIN(raw_item.shipping_limit_date) AS shipping_limit_timestamp,
            MAX(f.was_delivered_late) AS was_delivered_late,
            MAX(f.delivery_delay_days) AS delivery_delay_days,
            MAX(f.days_to_delivery) AS days_to_delivery
        FROM fact_order_items f
        LEFT JOIN stg_orders ord ON ord.order_id = f.order_id
        LEFT JOIN stg_order_items raw_item
            ON raw_item.order_id = f.order_id
           AND raw_item.order_item_id = f.order_item_id
        LEFT JOIN dim_product prod ON prod.product_key = f.product_key
        LEFT JOIN dim_category cat ON cat.category_key = prod.category_key
        LEFT JOIN dim_location cust_loc ON cust_loc.location_key = f.customer_location_key
        LEFT JOIN dim_location seller_loc ON seller_loc.location_key = f.seller_location_key
        LEFT JOIN dim_date date_dim ON date_dim.date_key = f.purchase_date_key
        WHERE f.was_delivered_late IS NOT NULL
        GROUP BY f.order_id
    )
    SELECT
        item_agg.*,
        COALESCE(payment_agg.payment_value, item_agg.total_item_value_sum) AS payment_value,
        payment_agg.payment_installments,
        COALESCE(payment_agg.payment_count, 0) AS payment_count,
        COALESCE(payment_agg.payment_types, 'unknown') AS payment_types
    FROM item_agg
    LEFT JOIN payment_agg ON payment_agg.order_id = item_agg.order_id;
    """
    with sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True, timeout=15) as conn:
        df = pd.read_sql_query(query, conn)

    df["purchase_date"] = pd.to_datetime(df["purchase_date"], errors="coerce")
    df["purchase_timestamp"] = pd.to_datetime(df["purchase_timestamp"], errors="coerce")
    df["approved_timestamp"] = pd.to_datetime(df["approved_timestamp"], errors="coerce")
    df["estimated_delivery_timestamp"] = pd.to_datetime(df["estimated_delivery_timestamp"], errors="coerce")
    df["shipping_limit_timestamp"] = pd.to_datetime(df["shipping_limit_timestamp"], errors="coerce")
    df["estimated_delivery_days"] = (
        df["estimated_delivery_timestamp"] - df["purchase_timestamp"]
    ).dt.total_seconds() / 86400
    df["shipping_limit_days"] = (
        df["shipping_limit_timestamp"] - df["purchase_timestamp"]
    ).dt.total_seconds() / 86400
    df["approval_delay_hours"] = (
        df["approved_timestamp"] - df["purchase_timestamp"]
    ).dt.total_seconds() / 3600
    df["estimated_delivery_day_of_week"] = df["estimated_delivery_timestamp"].dt.dayofweek
    df["shipping_limit_day_of_week"] = df["shipping_limit_timestamp"].dt.dayofweek
    df["same_state"] = (df["customer_state"] == df["seller_state"]).astype(int)
    df["freight_to_price_ratio"] = df["freight_sum"] / df["order_price_sum"].replace(0, np.nan)
    df["product_volume_cm3_avg"] = (
        df["product_length_cm_avg"] * df["product_height_cm_avg"] * df["product_width_cm_avg"]
    )
    df["distance_km"] = haversine_km(
        df["customer_lat"],
        df["customer_lng"],
        df["seller_lat"],
        df["seller_lng"],
    )
    df["distance_km"] = df["distance_km"].replace([np.inf, -np.inf], np.nan)
    df["route_state_pair"] = df["seller_state"].fillna("NA") + "_" + df["customer_state"].fillna("NA")
    df["payment_types"] = df["payment_types"].fillna("unknown")
    df["primary_category"] = df["primary_category"].fillna("unknown")
    return df


def make_features(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Series, list[str], list[str]]:
    leakage_columns = {
        "order_id",
        "purchase_date",
        "purchase_timestamp",
        "approved_timestamp",
        "estimated_delivery_timestamp",
        "shipping_limit_timestamp",
        "was_delivered_late",
        "delivery_delay_days",
        "days_to_delivery",
        "customer_lat",
        "customer_lng",
        "seller_lat",
        "seller_lng",
        "customer_city",
        "seller_city",
    }
    categorical_features = [
        "primary_category",
        "customer_state",
        "seller_state",
        "route_state_pair",
        "payment_types",
    ]
    numeric_features = [
        col
        for col in df.columns
        if col not in leakage_columns and col not in categorical_features
    ]
    X = df[numeric_features + categorical_features].copy()
    y = df["was_delivered_late"].astype(int)
    return X, y, numeric_features, categorical_features


def chronological_split(
    df: pd.DataFrame,
    validation_ratio: float = 0.1,
    test_ratio: float = 0.2,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    ordered = df.sort_values(["purchase_date", "order_id"]).index.to_numpy()
    test_start = int(len(ordered) * (1 - test_ratio))
    validation_start = int(len(ordered) * (1 - test_ratio - validation_ratio))
    return ordered[:validation_start], ordered[validation_start:test_start], ordered[test_start:]


def build_preprocessor(numeric_features: list[str], categorical_features: list[str]) -> ColumnTransformer:
    numeric_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
        ]
    )
    categorical_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore", min_frequency=50, sparse_output=False)),
        ]
    )
    return ColumnTransformer(
        transformers=[
            ("num", numeric_pipe, numeric_features),
            ("cat", categorical_pipe, categorical_features),
        ]
    )


def model_scores(model: Pipeline, X: pd.DataFrame) -> np.ndarray:
    if hasattr(model, "predict_proba"):
        return model.predict_proba(X)[:, 1]
    return model.decision_function(X)


def select_threshold(y_true: pd.Series, y_score: np.ndarray) -> float:
    precision, recall, thresholds = precision_recall_curve(y_true, y_score)
    if len(thresholds) == 0:
        return 0.5
    f1_values = 2 * precision[:-1] * recall[:-1] / np.maximum(precision[:-1] + recall[:-1], 1e-12)
    best_idx = int(np.nanargmax(f1_values))
    return float(thresholds[best_idx])


def predict_with_threshold(model: Pipeline, X: pd.DataFrame, threshold: float) -> np.ndarray:
    return (model_scores(model, X) >= threshold).astype(int)


def evaluate_model(
    name: str,
    model: Pipeline,
    threshold: float,
    X_test: pd.DataFrame,
    y_test: pd.Series,
) -> dict[str, float | str]:
    y_score = model_scores(model, X_test)
    y_pred = (y_score >= threshold).astype(int)

    metrics = {
        "model": name,
        "threshold": threshold,
        "accuracy": accuracy_score(y_test, y_pred),
        "balanced_accuracy": balanced_accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred, zero_division=0),
        "recall": recall_score(y_test, y_pred, zero_division=0),
        "f1": f1_score(y_test, y_pred, zero_division=0),
        "roc_auc": roc_auc_score(y_test, y_score),
        "average_precision": average_precision_score(y_test, y_score),
        "predicted_positive_rate": float(np.mean(y_pred)),
    }
    return metrics


def plot_target_distribution(df: pd.DataFrame) -> None:
    plt.figure(figsize=(8, 5))
    ax = sns.countplot(data=df, x="was_delivered_late", hue="was_delivered_late", palette=["#41788f", "#d95f02"], legend=False)
    ax.set_title("Розподіл цільової ознаки затримки доставки")
    ax.set_xlabel("Замовлення доставлено із затримкою")
    ax.set_ylabel("Кількість замовлень")
    ax.set_xticks([0, 1], ["Ні", "Так"])
    for container in ax.containers:
        ax.bar_label(container)
    plt.tight_layout()
    plt.savefig(OUT_DIR / "target_distribution.png", dpi=180)
    plt.close()


def plot_late_by_state(df: pd.DataFrame) -> None:
    state_stats = (
        df.groupby("customer_state")
        .agg(orders=("order_id", "count"), late_rate=("was_delivered_late", "mean"))
        .query("orders >= 100")
        .sort_values("late_rate", ascending=False)
        .head(15)
        .reset_index()
    )
    plt.figure(figsize=(10, 6))
    ax = sns.barplot(data=state_stats, y="customer_state", x="late_rate", color="#8c5a2b")
    ax.set_title("Найвища частка затримок за штатами покупців")
    ax.set_xlabel("Частка замовлень із затримкою")
    ax.set_ylabel("Штат покупця")
    ax.xaxis.set_major_formatter(lambda x, _: f"{x:.0%}")
    plt.tight_layout()
    plt.savefig(OUT_DIR / "late_rate_by_customer_state.png", dpi=180)
    plt.close()


def plot_distance_effect(df: pd.DataFrame) -> None:
    prepared = df.dropna(subset=["distance_km"]).copy()
    prepared["distance_bin"] = pd.qcut(prepared["distance_km"], q=10, duplicates="drop")
    distance_stats = (
        prepared.groupby("distance_bin", observed=False)
        .agg(distance_km=("distance_km", "median"), late_rate=("was_delivered_late", "mean"), orders=("order_id", "count"))
        .reset_index(drop=True)
    )
    plt.figure(figsize=(9, 5))
    ax = sns.lineplot(data=distance_stats, x="distance_km", y="late_rate", marker="o", color="#2a6f97")
    ax.set_title("Залежність частки затримок від відстані між продавцем і покупцем")
    ax.set_xlabel("Медіанна відстань у групі, км")
    ax.set_ylabel("Частка затримок")
    ax.yaxis.set_major_formatter(lambda x, _: f"{x:.0%}")
    plt.tight_layout()
    plt.savefig(OUT_DIR / "late_rate_by_distance.png", dpi=180)
    plt.close()


def plot_metrics(metrics_df: pd.DataFrame) -> None:
    long_df = metrics_df.melt(
        id_vars="model",
        value_vars=["balanced_accuracy", "precision", "recall", "f1", "roc_auc", "average_precision"],
        var_name="metric",
        value_name="value",
    )
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(data=long_df, x="metric", y="value", hue="model")
    ax.set_title("Порівняння якості моделей прогнозування затримки")
    ax.set_xlabel("Метрика")
    ax.set_ylabel("Значення")
    ax.set_ylim(0, 1)
    ax.legend(title="Модель", loc="lower right")
    plt.xticks(rotation=20, ha="right")
    plt.tight_layout()
    plt.savefig(OUT_DIR / "model_metrics_comparison.png", dpi=180)
    plt.close()


def plot_confusion(best_name: str, best_model: Pipeline, threshold: float, X_test: pd.DataFrame, y_test: pd.Series) -> None:
    y_pred = predict_with_threshold(best_model, X_test, threshold)
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(6, 5))
    ax = sns.heatmap(cm, annot=True, fmt="d", cmap="YlGnBu", cbar=False)
    ax.set_title(f"Матриця помилок: {best_name}")
    ax.set_xlabel("Прогноз")
    ax.set_ylabel("Факт")
    ax.set_xticklabels(["Без затримки", "Затримка"], rotation=15, ha="right")
    ax.set_yticklabels(["Без затримки", "Затримка"], rotation=0)
    plt.tight_layout()
    plt.savefig(OUT_DIR / "best_model_confusion_matrix.png", dpi=180)
    plt.close()


def plot_feature_importance(best_model: Pipeline, numeric_features: list[str], categorical_features: list[str]) -> None:
    classifier = best_model.named_steps["classifier"]

    preprocessor = best_model.named_steps["preprocessor"]
    feature_names = preprocessor.get_feature_names_out()

    if hasattr(classifier, "feature_importances_"):
        importance_values = classifier.feature_importances_
        title = "Найважливіші ознаки найкращої моделі"
        x_label = "Важливість ознаки"
        output_name = "feature_importance.png"
        sort_col = "importance_abs"
    elif hasattr(classifier, "coef_"):
        importance_values = classifier.coef_[0]
        title = "Найсильніші коефіцієнти найкращої моделі"
        x_label = "Коефіцієнт впливу на log-odds затримки"
        output_name = "feature_importance.png"
        sort_col = "importance_abs"
    else:
        return

    importance = pd.DataFrame({"feature": feature_names, "importance": importance_values})
    importance["importance_abs"] = importance["importance"].abs()
    importance["feature"] = (
        importance["feature"]
        .str.replace("num__", "", regex=False)
        .str.replace("cat__", "", regex=False)
        .str.replace("primary_category_", "category=", regex=False)
        .str.replace("customer_state_", "customer_state=", regex=False)
        .str.replace("seller_state_", "seller_state=", regex=False)
        .str.replace("route_state_pair_", "route=", regex=False)
        .str.replace("payment_types_", "payment=", regex=False)
    )
    top = importance.sort_values(sort_col, ascending=False).head(20).sort_values("importance")
    plt.figure(figsize=(10, 7))
    palette = ["#2a6f97" if value > 0 else "#8c5a2b" for value in top["importance"]]
    ax = sns.barplot(data=top, y="feature", x="importance", hue="feature", palette=palette, legend=False)
    ax.axvline(0, color="#333333", linewidth=0.9)
    ax.set_title(title)
    ax.set_xlabel(x_label)
    ax.set_ylabel("Ознака")
    plt.tight_layout()
    plt.savefig(OUT_DIR / output_name, dpi=180)
    plt.close()


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sns.set_theme(style="whitegrid", font="DejaVu Sans")

    df = load_dataset()
    df.to_csv(DATASET_PATH, index=False)

    X, y, numeric_features, categorical_features = make_features(df)
    train_idx, validation_idx, test_idx = chronological_split(df)
    X_train, X_test = X.loc[train_idx], X.loc[test_idx]
    y_train, y_test = y.loc[train_idx], y.loc[test_idx]
    X_validation, y_validation = X.loc[validation_idx], y.loc[validation_idx]

    class_balance = y_train.value_counts(normalize=True).to_dict()
    neg_share = class_balance.get(0, 0.0)
    pos_share = class_balance.get(1, 0.0)
    pos_weight = neg_share / pos_share if pos_share else 1.0

    models = {
        "Логістична регресія": LogisticRegression(
            max_iter=3000,
            class_weight="balanced",
            solver="lbfgs",
            random_state=RANDOM_STATE,
        ),
        "Дерево рішень": DecisionTreeClassifier(
            max_depth=12,
            min_samples_leaf=50,
            class_weight="balanced",
            random_state=RANDOM_STATE,
        ),
        "Випадковий ліс": RandomForestClassifier(
            n_estimators=250,
            max_depth=16,
            min_samples_leaf=20,
            class_weight="balanced_subsample",
            n_jobs=-1,
            random_state=RANDOM_STATE,
        ),
        "Градієнтний бустинг": HistGradientBoostingClassifier(
            max_iter=180,
            learning_rate=0.08,
            max_leaf_nodes=31,
            l2_regularization=0.05,
            class_weight={0: 1.0, 1: float(pos_weight)},
            random_state=RANDOM_STATE,
        ),
    }

    fitted_models: dict[str, Pipeline] = {}
    thresholds: dict[str, float] = {}
    metrics = []
    reports = {}
    for name, classifier in models.items():
        pipeline = Pipeline(
            steps=[
                ("preprocessor", build_preprocessor(numeric_features, categorical_features)),
                ("classifier", classifier),
            ]
        )
        pipeline.fit(X_train, y_train)
        fitted_models[name] = pipeline
        thresholds[name] = select_threshold(y_validation, model_scores(pipeline, X_validation))
        metrics.append(evaluate_model(name, pipeline, thresholds[name], X_test, y_test))
        reports[name] = classification_report(
            y_test,
            predict_with_threshold(pipeline, X_test, thresholds[name]),
            output_dict=True,
            zero_division=0,
        )

    metrics_df = pd.DataFrame(metrics).sort_values("average_precision", ascending=False)
    metrics_df.to_csv(REPORT_TABLES_PATH, index=False)

    best_name = metrics_df.iloc[0]["model"]
    best_model = fitted_models[str(best_name)]
    best_threshold = thresholds[str(best_name)]

    plot_target_distribution(df)
    plot_late_by_state(df)
    plot_distance_effect(df)
    plot_metrics(metrics_df)
    plot_confusion(str(best_name), best_model, best_threshold, X_test, y_test)
    plot_feature_importance(best_model, numeric_features, categorical_features)

    summary = {
        "source_database": str(DB_PATH.relative_to(ROOT)),
        "rows": int(len(df)),
        "columns": int(len(df.columns)),
        "target_positive_rate": float(df["was_delivered_late"].mean()),
        "train_rows": int(len(train_idx)),
        "validation_rows": int(len(validation_idx)),
        "test_rows": int(len(test_idx)),
        "train_period": [
            str(df.loc[train_idx, "purchase_date"].min().date()),
            str(df.loc[train_idx, "purchase_date"].max().date()),
        ],
        "validation_period": [
            str(df.loc[validation_idx, "purchase_date"].min().date()),
            str(df.loc[validation_idx, "purchase_date"].max().date()),
        ],
        "test_period": [
            str(df.loc[test_idx, "purchase_date"].min().date()),
            str(df.loc[test_idx, "purchase_date"].max().date()),
        ],
        "late_delay_days_mean": float(df.loc[df["was_delivered_late"] == 1, "delivery_delay_days"].mean()),
        "late_delay_days_median": float(df.loc[df["was_delivered_late"] == 1, "delivery_delay_days"].median()),
        "distance_km_median": float(df["distance_km"].median()),
        "distance_km_late_median": float(df.loc[df["was_delivered_late"] == 1, "distance_km"].median()),
        "distance_km_on_time_median": float(df.loc[df["was_delivered_late"] == 0, "distance_km"].median()),
        "best_model": str(best_name),
        "best_threshold": float(best_threshold),
        "metrics": metrics_df.to_dict(orient="records"),
        "numeric_features": numeric_features,
        "categorical_features": categorical_features,
        "classification_reports": reports,
    }
    SUMMARY_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")

    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
