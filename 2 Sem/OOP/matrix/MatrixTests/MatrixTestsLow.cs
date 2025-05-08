using System;
using MatrixLibrary;
using NUnit.Framework;

namespace MatrixTestsLow
{
    [TestFixture]
    [DefaultFloatingPointTolerance(0.001)]
    public class Tests
    {
        #region Startup Data

        #region ArraysCreateMatrix

        private static readonly object[] ArraysCreateMatrix =
        {
            new object[]
            {
                new double[3, 4]
                {
                    {1, 2, 3, 4},
                    {1, 2, 3, 4},
                    {1, 2, 3, 4}
                }
            }
        };

        #endregion

        #region ArraysEqualsException
        #pragma warning disable S1144
        #pragma warning disable IDE0052
        private static readonly object[] ArraysEqualsException =
        {
            new object[]
            {
                new double[,]{{1 ,1}}, 
                
                new double[,]
                {
                    {4, 3, 2},
                    {4, 3, 2},
                    {4, 3, 2},
                    {4, 3, 2}
                }
            }
        };
        #pragma warning restore
        #endregion

        #region ArraysPlusOperator

        private static readonly object[] ArraysPlusOperator =
        {
            new object[]
            {
                new double[3, 4]
                {
                    {1, 2, 3, 4},
                    {1, 2, 3, 4},
                    {1, 2, 3, 4}
                },
                new double[3, 4]
                {
                    {4, 3, 2, 1},
                    {4, 3, 2, 1},
                    {4, 3, 2, 1},
                },
                new double[3, 4]
                {
                    {5, 5, 5, 5},
                    {5, 5, 5, 5},
                    {5, 5, 5, 5},
                }
            }
        };

        #endregion

        #endregion
        
        #region ArraysMinusOperator

        private static readonly object[] ArraysMinusOperator =
        {
            new object[]
            {
                new double[3, 4]
                {
                    {1, 2, 3, 4},
                    {1, 2, 3, 4},
                    {1, 2, 3, 4}
                },
                new double[3, 4]
                {
                    {4, 3, 2, 1},
                    {4, 3, 2, 1},
                    {4, 3, 2, 1},
                },
                new double[3, 4]
                {
                    {-3, -1, 1, 3},
                    {-3, -1, 1, 3},
                    {-3, -1, 1, 3},
                }
            }
        };

        #endregion
        
        #region ArraysOperatorMultiply

        private static readonly object[] ArraysOperatorMultiply =
        {
            new object[]
            {
                new double[2, 2] {{2, 2}, {2, 2}}, new double[2, 2] {{2, 2}, {2, 2}}, new double[2, 2] {{8, 8}, {8, 8}}
            },
            new object[]
            {
                new double[2, 3]
                {
                    {1, 4, 2},
                    {2, 5, 1}
                },
                new double[3, 3]
                {
                    {3, 4, 2},
                    {3, 5, 7},
                    {1, 2, 1}
                },
                new double[2, 3]
                {
                    {17, 28, 32},
                    {22, 35, 40}
                }
            },
            new object[]
            {
                new double[4, 3]
                {
                    {1, 2, 3},
                    {1, 2, 3},
                    {1, 2, 3},
                    {1, 2, 3}
                },
                new double[3, 4]
                {
                    {4, 3, 2, 1},
                    {4, 3, 2, 1},
                    {4, 3, 2, 1},
                },
                new double[4, 4]
                {
                    {24, 18, 12, 6},
                    {24, 18, 12, 6},
                    {24, 18, 12, 6},
                    {24, 18, 12, 6}
                }
            }
        };
        
        #endregion
        
       
        [TestCaseSource(nameof(ArraysCreateMatrix))]
        public void CreateMatrixWithArrayPublicPropertiesReturnsCorrectValues(double[,] expectedArray)
        {
            var expectedRows = expectedArray.GetLength(0);
            var expectedColumns = expectedArray.GetLength(1);

            var matrix = new Matrix(expectedArray);

            Assert.AreEqual(expectedRows, matrix.Rows);
            Assert.AreEqual(expectedColumns, matrix.Columns);
        }
        
        [TestCase(3, 4)]
        [TestCase(3, 5)]
        [TestCase(2, 2)]
        public void CreateMatrixWithDimensionsPublicPropertiesReturnsCorrectValues(int expectedRows,
            int expectedColumns)
        {
            var matrix = new Matrix(expectedRows, expectedColumns);

            Assert.AreEqual(expectedRows, matrix.Rows);
            Assert.AreEqual(expectedColumns, matrix.Columns);
        }

        [TestCaseSource(nameof(ArraysCreateMatrix))]
        public void IndexerGetEachElementShouldReturnValue(double[,] array)
        {
            var matrix = new Matrix(array);

            var isValid = true;
            for (var i = 0; i < matrix.Rows; i++)
            {
                for (var j = 0; j < matrix.Columns; j++)
                {
                    if (Math.Abs(matrix[i, j] - array[i, j]) > 0.001) isValid = false;
                }
            }

            Assert.AreEqual(true, isValid, message: "Indexer works incorrectly.");
        }
        
        [TestCase(4, 3)]
        [TestCase(3, 4)]
        [TestCase(2, 2)]
        public void IndexerSetElementShouldChangeValue(int rows, int columns)
        {
            var matrix = new Matrix(rows, columns);
            const int expected1 = 1337;
            const int expected2 = 228;

            matrix[rows - 1, columns - 1] = expected1;
            matrix[0, 0] = expected2;

            Assert.AreEqual(expected1, matrix[rows - 1, columns - 1],
                message: "Set property in indexer works incorrectly.");
            Assert.AreEqual(expected2, matrix[0, 0], message: "Set property in indexer works incorrectly.");
        }

        [TestCaseSource(nameof(ArraysOperatorMultiply))]
        public void MultiplyMatrixReturnsResultMatrix(double[,] array1, double[,] array2,
            double[,] expectedArray)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);
            var expected = new Matrix(expectedArray);

            var actual = matrix1.Multiply(matrix2);

            Assert.AreEqual(expected.Array, actual.Array, "Multiply method works incorrectly.");
        }
        
        [TestCaseSource(nameof(ArraysPlusOperator))]
        public void AddMatrixReturnsResultMatrix(double[,] array1, double[,] array2,
            double[,] expectedArray)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);
            var expected = new Matrix(expectedArray);

            var actual = matrix1.Add(matrix2);

            Assert.AreEqual(expected.Array, actual.Array, message: "Add method works incorrectly.");
        }
        
        [TestCaseSource(nameof(ArraysMinusOperator))]
        public void SubtractMatrixReturnsResultMatrix(double[,] array1, double[,] array2,
            double[,] expectedArray)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);
            var expected = new Matrix(expectedArray);

            var actual = matrix1.Subtract(matrix2);

            Assert.AreEqual(expected.Array, actual.Array, message: "Subtract method works incorrectly.");
        }
        
        [TestCaseSource(nameof(ArraysCreateMatrix))]
        public void ToArrayReturnsMatrixAsArray(double[,] expectedArray)
        {
            var matrix = new Matrix(expectedArray);

            var arrayMatrix = matrix.Array;

            Assert.AreEqual(expectedArray, arrayMatrix,
                message: "ToArray method returns array that is not equal to expected.");
            
        }
        
        [TestCaseSource(nameof(ArraysPlusOperator))]
        public void PlusOperatorAddingMatricesReturnsMatrix(double[,] array1, double[,] array2,
            double[,] expectedArray)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);
            var expected = new Matrix(expectedArray);

            var actual = matrix1 + matrix2;

            Assert.AreEqual(expected.Array, actual.Array, message: "Plus operator works incorrectly.");
        }
        
        [TestCaseSource(nameof(ArraysMinusOperator))]
        public void MinusOperatorSubtractingMatricesReturnsMatrix(double[,] array1, double[,] array2,
            double[,] expectedArray)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);
            var expected = new Matrix(expectedArray);

            var actual = matrix1 - matrix2;

            Assert.AreEqual(expected.Array, actual.Array, message: "Minus operator works incorrectly.");
        }
        
        [TestCaseSource(nameof(ArraysOperatorMultiply))]
        public void MultiplyOperatorMultiplyMatricesReturnsMatrix(double[,] array1, double[,] array2,
            double[,] expectedArray)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);
            var expected = new Matrix(expectedArray);

            var actual = matrix1 * matrix2;

            Assert.AreEqual(expected.Array, actual.Array, message: "Multiply operator works incorrectly.");
        }
    }
}
