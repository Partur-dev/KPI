using System;

namespace MatrixLibrary
{
    public class MatrixException : Exception
    {
        public MatrixException() : base() { }
        public MatrixException(string message) : base(message) { }
        public MatrixException(string message, Exception innerException) : base(message, innerException) { }
    }

    public class Matrix : ICloneable
    {
        private readonly double[,] _matrix;

        public int Rows
        {
            get => _matrix.GetLength(0);
        }

        public int Columns
        {
            get => _matrix.GetLength(1);
        }

        public double[,] Array
        {
            get => (double[,])_matrix.Clone();
        }

        public Matrix(int rows, int columns)
        {
            if (rows <= 0 || columns <= 0)
                throw new ArgumentOutOfRangeException(
                    rows <= 0 ? nameof(rows) : nameof(columns),
                    "Matrix dimensions must be positive numbers");

            _matrix = new double[rows, columns];
        }

        public Matrix(double[,] array)
        {
            if (array == null)
                throw new ArgumentNullException(nameof(array), "Input array cannot be null");

            _matrix = (double[,])array.Clone();
        }

        public double this[int row, int column]
        {
            get
            {
                if (row < 0 || row >= Rows || column < 0 || column >= Columns)
                    throw new ArgumentException("Index is outside the matrix bounds");

                return _matrix[row, column];
            }
            set
            {
                if (row < 0 || row >= Rows || column < 0 || column >= Columns)
                    throw new ArgumentException("Index is outside the matrix bounds");

                _matrix[row, column] = value;
            }
        }

        public object Clone()
        {
            return new Matrix((double[,])_matrix.Clone());
        }

        public static Matrix operator +(Matrix matrix1, Matrix matrix2)
        {
            if (matrix1 == null)
                throw new ArgumentNullException(nameof(matrix1), "Input matrix cannot be null");

            return matrix1.Add(matrix2);
        }

        public static Matrix operator -(Matrix matrix1, Matrix matrix2)
        {
            if (matrix1 == null)
                throw new ArgumentNullException(nameof(matrix1), "Input matrix cannot be null");

            return matrix1.Subtract(matrix2);
        }

        public static Matrix operator *(Matrix matrix1, Matrix matrix2)
        {
            if (matrix1 == null)
                throw new ArgumentNullException(nameof(matrix1), "Input matrix cannot be null");

            return matrix1.Multiply(matrix2);
        }

        public static bool operator ==(Matrix matrix1, Matrix matrix2)
        {
            if (ReferenceEquals(matrix1, matrix2))
                return true;

            if (matrix1 is null || matrix2 is null)
                return false;

            return matrix1.Equals(matrix2);
        }

        public static bool operator !=(Matrix matrix1, Matrix matrix2)
        {
            return !(matrix1 == matrix2);
        }

        public Matrix Add(Matrix matrix)
        {
            if (matrix == null)
                throw new ArgumentNullException(nameof(matrix), "Input matrix cannot be null");

            if (Rows != matrix.Rows || Columns != matrix.Columns)
                throw new MatrixException("Matrix dimensions must be the same for addition");

            Matrix result = new Matrix(Rows, Columns);

            for (int i = 0; i < Rows; i++)
            {
                for (int j = 0; j < Columns; j++)
                {
                    result[i, j] = this[i, j] + matrix[i, j];
                }
            }

            return result;
        }

        public Matrix Subtract(Matrix matrix)
        {
            if (matrix == null)
                throw new ArgumentNullException(nameof(matrix), "Input matrix cannot be null");

            if (Rows != matrix.Rows || Columns != matrix.Columns)
                throw new MatrixException("Matrix dimensions must be the same for subtraction");

            Matrix result = new Matrix(Rows, Columns);

            for (int i = 0; i < Rows; i++)
            {
                for (int j = 0; j < Columns; j++)
                {
                    result[i, j] = this[i, j] - matrix[i, j];
                }
            }

            return result;
        }

        public Matrix Multiply(Matrix matrix)
        {
            if (matrix == null)
                throw new ArgumentNullException(nameof(matrix), "Input matrix cannot be null");

            if (Columns != matrix.Rows)
                throw new MatrixException("Number of columns in the first matrix must equal number of rows in the second matrix");

            Matrix result = new Matrix(Rows, matrix.Columns);

            for (int i = 0; i < Rows; i++)
            {
                for (int j = 0; j < matrix.Columns; j++)
                {
                    double sum = 0;
                    for (int k = 0; k < Columns; k++)
                    {
                        sum += this[i, k] * matrix[k, j];
                    }
                    result[i, j] = sum;
                }
            }

            return result;
        }

        public override bool Equals(object obj)
        {
            if (!(obj is Matrix))
                return false;

            Matrix other = (Matrix)obj;

            if (Rows != other.Rows || Columns != other.Columns)
                return false;

            for (int i = 0; i < Rows; i++)
            {
                for (int j = 0; j < Columns; j++)
                {

                    if (this[i, j] != other[i, j])
                        return false;
                }
            }

            return true;
        }

        public override int GetHashCode()
        {
            int hash = 17;

            for (int i = 0; i < Rows; i++)
            {
                for (int j = 0; j < Columns; j++)
                {
                    hash += this[i, j].GetHashCode();
                }
            }

            return hash;
        }
    }
}
