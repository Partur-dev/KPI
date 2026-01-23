#include <atomic>
#include <cstring>
#include <format>
#include <iostream>
#include <random>
#include <thread>

#include "btree.hh"
#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <GLFW/glfw3.h>

std::atomic<bool> g_isGenerating {false};
std::atomic<int> g_progress {0};
std::atomic<int> g_totalTarget {0};

void GenerateDataThread(BTree* db, int count) {
    std::mt19937 gen(std::random_device {}());
    std::uniform_int_distribution<int64_t> keyDist(1, 1000000);
    const char chars[] = "abcdefghijklmnopqrstuvwxyz";
    std::uniform_int_distribution<int> charDist(0, sizeof(chars) - 2);

    for (int i = 0; i < count; ++i) {
        int64_t key = keyDist(gen);
        std::string val;
        for (int j = 0; j < 8; ++j)
            val += chars[charDist(gen)];
        db->upsert(key, val);
        g_progress++;
    }
    g_isGenerating = false;
}

void DrawTreeRecursive(
    BTree& db,
    NodeIndex nodeIdx,
    std::set<NodeIndex>& openNodes,
    std::map<NodeIndex, Node>& uiCache
) {
    if (nodeIdx == NULL_INDEX)
        return;

    Node node;
    auto it = uiCache.find(nodeIdx);
    if (it != uiCache.end()) {
        node = it->second;
    } else {
        db.readNodeForVis(nodeIdx, node);
        uiCache[nodeIdx] = node;
    }

    std::string nodeLabel = std::format("Node #{} ({} keys) {}", nodeIdx, node.num_keys, node.is_leaf ? "[Leaf]" : "");

    if (node.is_leaf)
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.4f, 1.0f, 0.4f, 1.0f));
    else
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.4f, 0.8f, 1.0f, 1.0f));

    bool isTrackedOpen = openNodes.count(nodeIdx);
    ImGui::SetNextItemOpen(isTrackedOpen);

    bool isOpen = ImGui::TreeNodeEx(nodeLabel.c_str());
    ImGui::PopStyleColor();

    if (isOpen) {
        openNodes.insert(nodeIdx);

        if (ImGui::BeginTable("Keys", 2, ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg)) {
            ImGui::TableSetupColumn("Key");
            ImGui::TableSetupColumn("Value");
            ImGui::TableHeadersRow();
            for (int i = 0; i < node.num_keys; i++) {
                ImGui::TableNextRow();
                ImGui::TableSetColumnIndex(0);
                ImGui::Text("%lld", node.records[i].key);
                ImGui::TableSetColumnIndex(1);
                ImGui::Text("%s", node.records[i].value.data);
            }
            ImGui::EndTable();
        }

        if (!node.is_leaf) {
            ImGui::Separator();
            ImGui::TextDisabled("Children:");
            ImGui::Indent();
            for (int i = 0; i <= node.num_keys; i++) {
                DrawTreeRecursive(db, node.children[i], openNodes, uiCache);
            }
            ImGui::Unindent();
        }
        ImGui::TreePop();
    } else {
        openNodes.erase(nodeIdx);
    }
}

int main() {
    glfwSetErrorCallback([](int error, const char* description) {
        std::cerr << "GLFW Error " << error << ": " << description << std::endl;
    });

    if (!glfwInit())
        return 1;

#if defined(__APPLE__)
    const char* glsl_version = "#version 150";
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#else
    const char* glsl_version = "#version 130";
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
#endif

    GLFWwindow* window = glfwCreateWindow(1280, 720, "Lab #4", nullptr, nullptr);
    if (!window)
        return 1;

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();

    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    float fontSize = 18.0f;

    bool loaded = false;

#if defined(_WIN32)
    loaded = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segoeui.ttf", fontSize) != nullptr;
    if (!loaded)
        loaded = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segoeuiv.ttf", fontSize) != nullptr;
#elif defined(__APPLE__)
    loaded = io.Fonts->AddFontFromFileTTF("/System/Library/Fonts/SFNS.ttf", fontSize) != nullptr;
    if (!loaded)
        loaded = io.Fonts->AddFontFromFileTTF("/System/Library/Fonts/Supplemental/SF Pro.ttf", fontSize) != nullptr;
#endif

    if (!loaded) {
        io.Fonts->AddFontDefault();
    }

    io.FontDefault = io.Fonts->Fonts.back();

    ImGui::StyleColorsDark();
    ImGuiStyle& style = ImGui::GetStyle();
    ImVec4* colors = style.Colors;

    // Primary background
    colors[ImGuiCol_WindowBg] = ImVec4(0.07f, 0.07f, 0.09f, 1.00f); // #131318
    colors[ImGuiCol_MenuBarBg] = ImVec4(0.12f, 0.12f, 0.15f, 1.00f); // #131318

    colors[ImGuiCol_PopupBg] = ImVec4(0.18f, 0.18f, 0.22f, 1.00f);

    // Headers
    colors[ImGuiCol_Header] = ImVec4(0.18f, 0.18f, 0.22f, 1.00f);
    colors[ImGuiCol_HeaderHovered] = ImVec4(0.30f, 0.30f, 0.40f, 1.00f);
    colors[ImGuiCol_HeaderActive] = ImVec4(0.25f, 0.25f, 0.35f, 1.00f);

    // Buttons
    colors[ImGuiCol_Button] = ImVec4(0.20f, 0.22f, 0.27f, 1.00f);
    colors[ImGuiCol_ButtonHovered] = ImVec4(0.30f, 0.32f, 0.40f, 1.00f);
    colors[ImGuiCol_ButtonActive] = ImVec4(0.35f, 0.38f, 0.50f, 1.00f);

    // Frame BG
    colors[ImGuiCol_FrameBg] = ImVec4(0.15f, 0.15f, 0.18f, 1.00f);
    colors[ImGuiCol_FrameBgHovered] = ImVec4(0.22f, 0.22f, 0.27f, 1.00f);
    colors[ImGuiCol_FrameBgActive] = ImVec4(0.25f, 0.25f, 0.30f, 1.00f);

    // Tabs
    colors[ImGuiCol_Tab] = ImVec4(0.18f, 0.18f, 0.22f, 1.00f);
    colors[ImGuiCol_TabHovered] = ImVec4(0.35f, 0.35f, 0.50f, 1.00f);
    colors[ImGuiCol_TabActive] = ImVec4(0.25f, 0.25f, 0.38f, 1.00f);
    colors[ImGuiCol_TabUnfocused] = ImVec4(0.13f, 0.13f, 0.17f, 1.00f);
    colors[ImGuiCol_TabUnfocusedActive] = ImVec4(0.20f, 0.20f, 0.25f, 1.00f);

    // Title
    colors[ImGuiCol_TitleBg] = ImVec4(0.12f, 0.12f, 0.15f, 1.00f);
    colors[ImGuiCol_TitleBgActive] = ImVec4(0.15f, 0.15f, 0.20f, 1.00f);
    colors[ImGuiCol_TitleBgCollapsed] = ImVec4(0.10f, 0.10f, 0.12f, 1.00f);

    // Borders
    colors[ImGuiCol_Border] = ImVec4(0.20f, 0.20f, 0.25f, 0.50f);
    colors[ImGuiCol_BorderShadow] = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);

    // Text
    colors[ImGuiCol_Text] = ImVec4(0.90f, 0.90f, 0.95f, 1.00f);
    colors[ImGuiCol_TextDisabled] = ImVec4(0.50f, 0.50f, 0.55f, 1.00f);

    // Highlights
    colors[ImGuiCol_CheckMark] = ImVec4(0.50f, 0.70f, 1.00f, 1.00f);
    colors[ImGuiCol_SliderGrab] = ImVec4(0.50f, 0.70f, 1.00f, 1.00f);
    colors[ImGuiCol_SliderGrabActive] = ImVec4(0.60f, 0.80f, 1.00f, 1.00f);
    colors[ImGuiCol_ResizeGrip] = ImVec4(0.50f, 0.70f, 1.00f, 0.50f);
    colors[ImGuiCol_ResizeGripHovered] = ImVec4(0.60f, 0.80f, 1.00f, 0.75f);
    colors[ImGuiCol_ResizeGripActive] = ImVec4(0.70f, 0.90f, 1.00f, 1.00f);

    // Scrollbar
    colors[ImGuiCol_ScrollbarBg] = ImVec4(0.10f, 0.10f, 0.12f, 1.00f);
    colors[ImGuiCol_ScrollbarGrab] = ImVec4(0.30f, 0.30f, 0.35f, 1.00f);
    colors[ImGuiCol_ScrollbarGrabHovered] = ImVec4(0.40f, 0.40f, 0.50f, 1.00f);
    colors[ImGuiCol_ScrollbarGrabActive] = ImVec4(0.45f, 0.45f, 0.55f, 1.00f);

    // Style tweaks
    style.FrameRounding = 5.0f;
    style.GrabRounding = 5.0f;
    style.TabRounding = 5.0f;
    style.PopupRounding = 5.0f;
    style.ScrollbarRounding = 5.0f;
    style.WindowPadding = ImVec2(10, 10);
    style.FramePadding = ImVec2(6, 4);
    style.ItemSpacing = ImVec2(8, 6);
    style.PopupBorderSize = 0.f;

    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init(glsl_version);

    BTree db;
    std::set<NodeIndex> openNodes;

    // --- UI CACHE ---
    std::map<NodeIndex, Node> uiNodeCache;

    int inputKey = 0;
    char inputValue[40] = "";
    char searchResult[128] = "Ready.";

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        // --- Controls ---
        {
            ImGui::SetNextWindowPos(ImVec2(0, 0));
            ImGui::SetNextWindowSize(ImVec2(350, 720));
            ImGui::Begin(
                "Controls",
                nullptr,
                ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoTitleBar
            );

            ImGui::Text("High-Degree B-Tree (t=%d)", DEGREE);
            if (!uiNodeCache.empty())
                ImGui::TextColored(ImVec4(0, 1, 0, 1), "UI Cache: %zu nodes", uiNodeCache.size());

            ImGui::SeparatorText("Record");

            bool busy = g_isGenerating;
            if (busy)
                ImGui::BeginDisabled();

            ImGui::InputInt("Key", &inputKey);
            ImGui::InputText("Value", inputValue, 40);

            ImGui::SeparatorText("Actions");
            if (ImGui::Button("UPSERT", ImVec2(330, 30))) {
                std::string msg = db.upsert(inputKey, inputValue);
                uiNodeCache.clear();
                snprintf(searchResult, 128, "%s", msg.c_str());
            }

            if (ImGui::Button("DELETE", ImVec2(330, 30))) {
                std::string msg = db.remove(inputKey);
                uiNodeCache.clear();
                snprintf(searchResult, 128, "%s", msg.c_str());
            }

            if (ImGui::Button("FIND", ImVec2(330, 30))) {
                auto res = db.getWithStats(inputKey);
                snprintf(
                    searchResult,
                    128,
                    "Found: %d\n%s\nComparisons: %d",
                    res.found,
                    res.value.c_str(),
                    res.comparisons
                );
            }

            if (ImGui::Button("FIND & OPEN TREE", ImVec2(330, 30))) {
                auto [path, comps] = db.getPathToKey(inputKey);
                if (!path.empty()) {
                    openNodes.clear();
                    for (NodeIndex idx : path)
                        openNodes.insert(idx);
                    snprintf(searchResult, 128, "Expanded to key %d\nComparisons: %d", inputKey, comps);
                } else {
                    snprintf(searchResult, 128, "Key %d not found.\nComparisons: %d", inputKey, comps);
                }
            }
            if (busy)
                ImGui::EndDisabled();

            ImGui::Dummy(ImVec2(0, 20));
            ImGui::SeparatorText("Bulk");

            if (!busy) {
                if (ImGui::Button("GENERATE 5000 RANDOM", ImVec2(330, 40))) {
                    uiNodeCache.clear();
                    g_totalTarget = 5000;
                    g_progress = 0;
                    g_isGenerating = true;
                    std::thread t(GenerateDataThread, &db, 5000);
                    t.detach();
                }
            } else {
                float fraction = (float)g_progress / (float)g_totalTarget;
                char overlay[32];
                snprintf(overlay, sizeof(overlay), "%d / %d", (int)g_progress, (int)g_totalTarget);
                ImGui::ProgressBar(fraction, ImVec2(330, 40), overlay);
                ImGui::TextColored(ImVec4(1, 1, 0, 1), "Generating... Paused.");
            }

            ImGui::Dummy(ImVec2(0, 20));
            ImGui::SeparatorText("Status");
            ImGui::TextWrapped("%s", searchResult);
            ImGui::End();
        }

        // --- Visualization ---
        {
            ImGui::SetNextWindowPos(ImVec2(350, 0));
            ImGui::SetNextWindowSize(ImVec2(930, 720));
            ImGui::Begin(
                "Disk Visualization",
                nullptr,
                ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoTitleBar
            );

            if (g_isGenerating) {
                ImGui::Text("Visualization disabled during bulk insertion.");
            } else {
                NodeIndex root = db.getRootIndex();
                ImGui::Text("Root Index: %lld", root);
                ImGui::SameLine();
                if (ImGui::SmallButton("Collapse All"))
                    openNodes.clear();

                ImGui::Separator();
                if (root != NULL_INDEX) {
                    DrawTreeRecursive(db, root, openNodes, uiNodeCache);
                } else {
                    ImGui::Text("Tree is empty.");
                }
            }
            ImGui::End();
        }

        ImGui::Render();
        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        glfwSwapBuffers(window);
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
