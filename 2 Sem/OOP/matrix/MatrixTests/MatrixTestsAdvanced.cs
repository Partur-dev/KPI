using System;
using MatrixLibrary;
using NUnit.Framework;

namespace MatrixTestsAdvanced
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

        #region ArraysPlusAndMinusOperatorException

        private static readonly object[] ArraysPlusAndMinusOperatorException =
        {
            new object[] {new double[1, 1] { { 1 } }, new double[1, 0] { { }}},
        };

        #endregion
        
       
        #region ArraysOperatorMultiplyException

        private static readonly object[] ArraysOperatorMultiplyException =
        {
            new object[] {new double[1, 1] {{1}}, new double[0, 0] { }},
        };

        #endregion

        #region ArraysEquals

        private static readonly object[] ArraysEquals =
        {
            new object[] {new double[1, 1] {{1}}, new double[1, 1] { {1} }, true},
            new object[] {new double[1, 1] {{1}}, new double[1, 1] { {-1} }, false}
        };

        #endregion

        #region ArraysEqualsTrowsExceptions

        private static readonly object[] ArraysEqualsTrowsExceptions =
        {
            new object[] {new double[1,2]{{1, 2}}, new double[2,2]{{1, 2}, {1, 2}}},
            new object[] {new double[2,1]{{1}, {1}}, new double[2,2]{{1, 2}, {1, 2}}}
        };

        #endregion
        
        #endregion

        [TestCase(4, 3)]
        [TestCase(3, 4)]
        public void IndexerGetElementOutOfRangeArgumentExceptionThrown(int rows, int columns)
        {
            var matrix = new Matrix(rows, columns);
            var expectedException = typeof(ArgumentException);
            
            var actException = Assert.Catch(() => _ = matrix[-1, -1]);

            Assert.AreEqual(expectedException, actException.GetType(),
                message: "Indexer should throw argument exception in case of nonexistent index.");
        }

        [TestCase(4, 3)]
        [TestCase(3, 4)]
        public void IndexerSetElementOutOfRangeArgumentExceptionThrown(int rows, int columns)
        {
            var matrix = new Matrix(rows, columns);
            var expectedException = typeof(ArgumentException);

            var actException = Assert.Catch(() => matrix[-1, -1] = 1337);

            Assert.AreEqual(expectedException, actException.GetType(), 
                message: "Set property in indexer should throw argument exception in case of nonexistent index.");
        }
        

        [TestCase(-1, 2)]
        [TestCase(1, -2)]
        public void CreateMatrixWithNegativeDimensionsArgumentOutOfRangeExceptionThrown(int rows, int columns)
        {
            var expectedException = typeof(ArgumentOutOfRangeException);

            var actException = Assert.Catch(() => new Matrix(rows, columns));

            Assert.AreEqual(expectedException, actException.GetType(), message: "Matrix can't be created with negative dimensions.");
        }

        [Test]
        public void CreateMatrixWithNullArgumentNullExceptionThrown()
        {
            var expectedException = typeof(ArgumentNullException);

            var actException = Assert.Catch(() => new Matrix(null));

            Assert.AreEqual(expectedException, actException.GetType(), 
                message: "Matrix can't be created with null argument.");
        }
        
        [TestCaseSource(nameof(ArraysPlusAndMinusOperatorException))]
        public void PlusOperatorMatricesHaveInappropriateDimensionsMatrixExceptionThrown(double[,] array1,
            double[,] array2)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);

            var expectedException = Type.GetType("MatrixLibrary.MatrixException, MatrixLibrary");
            var actException = Assert.Catch(() => _ = matrix1 + matrix2);

            Assert.NotNull(expectedException, message: "'MatrixException' is not implemented.");
            Assert.AreEqual(expectedException, actException.GetType(), 
                message: "Plus operator should throw matrix exception in case of inappropriate matrices dimensions.");
        }

        [TestCaseSource(nameof(ArraysPlusAndMinusOperatorException))]
        public void MinusOperatorMatricesHaveInappropriateDimensionsMatrixExceptionThrown(double[,] array1,
            double[,] array2)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);

            var expectedException = Type.GetType("MatrixLibrary.MatrixException, MatrixLibrary");
            var actException = Assert.Catch(() => _ = matrix1 - matrix2);

            Assert.NotNull(expectedException, message: "'MatrixException' is not implemented.");
            Assert.AreEqual(expectedException, actException.GetType(), 
                message: "Minus operator should throw matrix exception in case of inappropriate matrices dimensions.");
        }
        
        [TestCaseSource(nameof(ArraysOperatorMultiplyException))]
        public void MultiplyOperatorMatricesHaveInappropriateDimensionsMatrixExceptionThrown(double[,] array1,
            double[,] array2)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);

            var expectedException = Type.GetType("MatrixLibrary.MatrixException, MatrixLibrary");
            var actException = Assert.Catch(() => _ = matrix1 * matrix2);

            Assert.NotNull(expectedException, message: "'MatrixException' is not implemented.");
            Assert.AreEqual(expectedException, actException.GetType(), message:
                "Multiply operator should throw matrix exception in case of inappropriate matrices dimensions.");
        }
        
        [TestCaseSource(nameof(ArraysOperatorMultiplyException))]
        public void MultiplyMatricesHaveInappropriateDimensionsMatrixExceptionThrown(double[,] array1,
            double[,] array2)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);
            
            var expectedException = Type.GetType("MatrixLibrary.MatrixException, MatrixLibrary");
            var actException = Assert.Catch(() => matrix1.Multiply(matrix2));

            Assert.NotNull(expectedException, message: "'MatrixException' is not implemented.");
            Assert.AreEqual(expectedException, actException.GetType(), message: "Multiply method should throw matrix exception in case of inappropriate matrices dimensions.");
        }
        
        [TestCaseSource(nameof(ArraysPlusAndMinusOperatorException))]
        public void AddMatricesHaveInappropriateDimensionsMatrixExceptionThrown(double[,] array1,
            double[,] array2)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);
            
            var expectedException = Type.GetType("MatrixLibrary.MatrixException, MatrixLibrary");
            var actException = Assert.Catch(() => matrix1.Add(matrix2));

            Assert.NotNull(expectedException, message: "'MatrixException' is not implemented.");
            Assert.AreEqual(expectedException, actException.GetType(), message: "Add method should throw matrix exception in case of inappropriate matrices dimensions.");
        }
        
        [TestCaseSource(nameof(ArraysPlusAndMinusOperatorException))]
        public void SubtractMatricesHaveInappropriateDimensionsMatrixExceptionThrown(double[,] array1,
            double[,] array2)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);

            var expectedException = Type.GetType("MatrixLibrary.MatrixException, MatrixLibrary");
            var actException = Assert.Catch(() => matrix1.Subtract(matrix2));

            Assert.NotNull(expectedException, message: "'MatrixException' is not implemented.");
            Assert.AreEqual(expectedException, actException.GetType(), message: "Subtract method should throw matrix exception in case of inappropriate matrices dimensions.");
        }

        [Test]
        public void PlusOperatorThrowsArgumentNullExceptionsIfFirstArgumentIsNull()
        {
            Matrix matrix1 = null;
            Matrix matrix2 = new Matrix(1, 1);

            Assert.Catch<ArgumentNullException>(() =>
            {
                var res1 = matrix1 + matrix2;
            },message:"Operator '+' should throw ArgumentNullException if one of arguments is null.");
        }
        
        [Test]
        public void PlusOperatorThrowsArgumentNullExceptionsIfSecondArgumentIsNull()
        {
            Matrix matrix1 = new Matrix(1, 1);
            Matrix matrix2 = null;

            Assert.Catch<ArgumentNullException>(() =>
            {
                var res1 = matrix1 + matrix2;
            },message:"Operator '+' should throw ArgumentNullException if one of arguments is null.");
        }
        
        [Test]
        public void SubtractOperatorThrowsArgumentNullExceptionsIfFirstArgumentIsNull()
        {
            Matrix matrix1 = null;
            Matrix matrix2 = new Matrix(1, 1);

            Assert.Catch<ArgumentNullException>(() =>
            {
                var res1 = matrix1 - matrix2;
            },message:"Operator '-' should throw ArgumentNullException if one of arguments is null.");
        }
        
        [Test]
        public void SubtractOperatorThrowsArgumentNullExceptionsIfSecondArgumentIsNull()
        {
            Matrix matrix1 = new Matrix(1, 1);
            Matrix matrix2 = null;

            Assert.Catch<ArgumentNullException>(() =>
            {
                var res1 = matrix1 - matrix2;
            },message:"Operator '-' should throw ArgumentNullException if one of arguments is null.");
        }
        
        [Test]
        public void MultiplyOperatorThrowsArgumentNullExceptionsIfFirstArgumentIsNull()
        {
            Matrix matrix1 = null;
            Matrix matrix2 = new Matrix(1, 1);

            Assert.Catch<ArgumentNullException>(() =>
            {
                var res1 = matrix1 * matrix2;
            },message:"Operator '*' should throw ArgumentNullException if one of arguments is null.");
        }
        
        [Test]
        public void MultiplyOperatorThrowsArgumentNullExceptionsIfSecondArgumentIsNull()
        {
            Matrix matrix1 = new Matrix(1, 1);
            Matrix matrix2 = null;

            Assert.Throws<ArgumentNullException>(() =>
            {
                var res1 = matrix1 * matrix2;
            },message:"Operator '*' should throw ArgumentNullException if one of arguments is null.");
        }
        
        [Test]
        public void AddThrowsArgumentNullExceptionsIfArgumentIsNull()
        {
            Matrix matrix1 = new Matrix(1, 1);
            Matrix matrix2 = null;

            Assert.Throws< ArgumentNullException >(() =>
            {
                matrix1.Add(matrix2);
            },message:"Method 'Add' should throw ArgumentNullException if one of arguments is null.");
        }
        
        [Test]
        public void SubtractThrowsArgumentNullExceptionsIfArgumentIsNull()
        {
            Matrix matrix1 = new Matrix(1, 1);
            Matrix matrix2 = null;

            Assert.Throws<ArgumentNullException>(() =>
            {
                matrix1.Subtract(matrix2);
            },message:"Method 'Subtract' should throw ArgumentNullException if one of arguments is null.");
        }
        
        [Test]
        public void MultiplyThrowsArgumentNullExceptionsIfArgumentIsNull()
        {
            Matrix matrix1 = new Matrix(1, 1);
            Matrix matrix2 = null;

            Assert.Throws<ArgumentNullException>(() =>
            {
                matrix1.Multiply(matrix2);
            },message:"Method 'Multiply' should throw ArgumentNullException if one of arguments is null.");
        }
        

        [TestCaseSource(nameof(ArraysEquals))]
        public void EqualsCompareMatricesReturnsCorrectBoolean(double[,] array1, double[,] array2,
            bool expectedResult)
        {
            // Arrange
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);

            // Act
            var actualResult = matrix1.Equals(matrix2);

            // Assert
            Assert.AreEqual(expectedResult, actualResult,
                message: "Equals method doesn't compares matrices correctly.");
        }
        
        [Test]
        public void EqualsCompareWithNullReturnsFalse()
        {
            // Arrange
            var array = new double[2, 2] {{1, 2}, {1, 2}};
            var matrix = new Matrix(array);
            // Act
            #pragma warning disable CA1508
            var result = matrix.Equals(null);
            #pragma warning restore
            // Assert
            Assert.AreEqual(false, result, message: "Equals method doesn't compares matrices correctly.");
        }
        
        [Test]
        public void EqualsCompareWithNotMatrixReturnsFalse()
        {
            var array = new double[2, 2] {{1, 2}, {1, 2}};
            var matrix = new Matrix(array);

            var result = matrix.Equals(1337);
            
            Assert.AreEqual(false, result, message: "Equals method doesn't compares matrices correctly.");
        }
        
        [TestCaseSource(nameof(ArraysEqualsTrowsExceptions))]
        public void EqualsCompareIncomparableMatricesDoesntThrowException(double[,] array1, double[,] array2)
        {
            var matrix1 = new Matrix(array1);
            var matrix2 = new Matrix(array2);

            Assert.DoesNotThrow(() => { 
                matrix1.Equals(matrix2);
                matrix2.Equals(matrix1);
            }, message:"Equals should not throw exceptions.");
        }
        
        [TestCaseSource(nameof(ArraysCreateMatrix))]
        public void CloneShouldReturnDeepCopy(double[,] array)
        {
            var matrix = new Matrix(array);

            var matrixClone = (Matrix) matrix.Clone();

            var referenceEquals = ReferenceEquals(matrix, matrixClone);
            
            Assert.AreEqual(matrix, matrixClone, 
                message: "Matrices should be equal.");
            Assert.AreEqual(false, referenceEquals, 
                message: "Matrix and its clone should not refer to the same object.");
        }
    }
}
