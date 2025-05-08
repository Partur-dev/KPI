using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using Functions;


namespace Function.Tests
{
     [TestFixture]
     [DefaultFloatingPointTolerance(0.001)]
    public class Tests
    {
        #region Setup
        private readonly Type type = typeof(DemoFunction);

        #pragma warning disable IDE0052
        #pragma warning disable S1144
        static readonly object[] Params =
        {
            new TestCaseData("Transform",new List<KeyValuePair<int,Type>>(){
            new KeyValuePair<int, Type>(1,typeof(int[])),
            new KeyValuePair<int, Type>(1,typeof(SortOrder)),


            },2

                ),

            new TestCaseData("IsSorted",new List<KeyValuePair<int,Type>>(){
            new KeyValuePair<int, Type>(1,typeof(int[])),
            new KeyValuePair<int, Type>(1,typeof(SortOrder)),

            },2),

            new TestCaseData("MultArithmeticElements",new List<KeyValuePair<int,Type>>(){
            new KeyValuePair<int, Type>(2,typeof(double)),
            new KeyValuePair<int, Type>(1,typeof(int))
            },3),

              new TestCaseData("SumGeometricElements",new List<KeyValuePair<int,Type>>(){
            new KeyValuePair<int, Type>(3,typeof(double))
            },3),


        };
        #pragma warning restore

        #endregion


        #region Reflection 


        [TestCase("Transform", typeof(void))]
        [TestCase("IsSorted", typeof(bool))]
        [TestCase("MultArithmeticElements", typeof(double))]
        [TestCase("SumGeometricElements", typeof(double))]
        
        public void MethodExistWithCorrectSignatureAndReturnedValue(string name, Type sort)
        {
            var method = type.GetMethod(name);
            if (method != null)
            {
                if (sort == method.ReturnType && method.IsStatic && method.IsPublic)
                {
                    Assert.True(true);
                }
                else
                {
                    Assert.Fail(message: $"Method '{name}' has incorrect returned value .Also check if method is public and  static ");
                }
            }
            else
            {
                Assert.Fail($"Method '{name}' doesen't exist");
            }

        }


        [TestCaseSource("Params")]
        public void MethodHasCorrectTypeAndAmountOfParameters(string name, List<KeyValuePair<int, Type>> parameters, int length)
        {
            var method = type.GetMethod(name);
            if (method != null)
            {
                var prms = method.GetParameters();

                if (prms != null && prms.Length == length)
                {
                    foreach (var item in parameters)
                    {
                        var ex_count = item.Key;
                        var exp_type = item.Value;
                        var check = prms.Count(x => x.ParameterType == exp_type);
                        if (ex_count != check)
                        {
                            Assert.Fail(message: $"Amount of '{name}' method  parameters isn't correct  ");
                        }
                    }
                }
                else
                {
                    Assert.Fail(message: $"Amount of {name} method  parameters is incorrect ");
                }
            }
            else
            {
                Assert.Fail($"Method '{name}' doesen't exist ");

            }

        }



        [TestCase("Transform", new string[] { "array", "order" })]
        [TestCase("IsSorted", new string[] { "array", "order" })]
        [TestCase("MultArithmeticElements", new string[] { "a", "t", "n" })]
        [TestCase("SumGeometricElements", new string[] { "a", "t", "alim" })]
        public void MethodHasCorrectParameterNames(string name, string[] paramNames)
        {
            var method = type.GetMethod(name);
            if (method != null)
            {
                var parameters = type.GetMethod(name).GetParameters();
                if (parameters != null)
                {
                    if (paramNames.Length == parameters.Length)
                    {
                        foreach (var item in paramNames)
                        {
                            var exp_name = item;
                            var count = parameters.Count(x => x.Name == exp_name);
                            if (count != 1)
                            {
                                Assert.Fail(message: $"There are no '{exp_name}' parameter in method {name} ");
                            }
                        }
                    }
                    else
                    {
                        Assert.Fail(message: $"Amount of '{name}' method parameters is incorrect ");
                    }
                }
                else
                {
                    Assert.Fail($"There are not parameters in method '{name}' ");
                }

            }
            else
            {
                Assert.Fail($"Method '{name}' doesen't exist ");
            }

        }
        #endregion


        #region Methods 

        #region Act & Assert methods for tests below 
        void CheckTransform(int[] array, SortOrder order, int[] expected)
        {
            string name = "Transform";
            var method = type.GetMethod(name);
            if (method != null)
            {
                method.Invoke(type, new object[] { array, order });
                Assert.AreEqual(expected, array, message: $" '{name}' method works incorrectly  ");
            }
            else
            {
                Assert.Fail(message: $" '{name}' method doesent exist ");
            }
        }


        void CheckIsSorted(int[] array, SortOrder order, bool expected)
        {
            string name = "IsSorted";
            var method = type.GetMethod(name);
            if (method != null)
            {
                var sort = (bool)method.Invoke(type, new object[] { array, order });
                Assert.AreEqual(expected, sort, message: $"'{name}' method works incorrectly");
                               
            }
            else
            {
                Assert.Fail($" '{name}' method doesen't exist");
            }
        }


        void CheckMult(double a, double t, int n, double expected)
        {
            string name = "MultArithmeticElements";
            var method = type.GetMethod(name);
            if (method != null)
            {
                var mul = (double)type.GetMethod(name).Invoke(type, new object[] { a, t, n });

                Assert.AreEqual(expected, mul, message: $" '{name}' method works incorrectly");

            }
            else
            {
                Assert.Fail($"Method {name} doesen't exist ");
            }

        }


        void CheckSum(double a, double t, double alim, double expected)
        {
            string name = "SumGeometricElements";
            var method = type.GetMethod(name);
            if (method != null)
            {
                var sum = (double)type.GetMethod(name).Invoke(type, new object[] { a, t, alim });
                Assert.AreEqual(expected, sum, message: $" '{name}' method works incorrectly");
            }
            else
            {
                Assert.Fail($"Method '{name}' doesen't exist");
            }

        }
        #endregion


        #region Transform 
        [Test]
        public void TransformWithAscendingSortNotChangeArray()
        {
            //Arrange 
            int[][] actual = { new int[] { 5, 17, 24, 88, 33, 2 }, new int[] { 15, 10, 3 } };
            var order = SortOrder.Ascending;
            int[][] expected = { new int[] { 5, 17, 24, 88, 33, 2 }, new int[] { 15, 10, 3 } };

            //Assert 
            for (int i = 0; i < actual.Length; i++)
            {
                CheckTransform(actual[i], order, expected[i]);
            }            

        }


        [Test]
        public void TransformWithAscendingSortChangeArray()
        {

            //Arrange      
            int[][] actual = { new int[] { 25, 30, 60, 100 }, new int[] { 0, 0, 0, 0 } };
            var order = SortOrder.Ascending;
            int[][] expected = { new int[] { 25, 31, 62, 103 }, new int[] { 0, 1, 2, 3 } };

            for (int i = 0; i < expected.Length; i++)
            {
                CheckTransform(actual[i], order, expected[i]);
            }

        }


        [Test]
        public void TransformWithDescendingSortChangeArray()
        {
            //Arrange      
            int[][] actual = { new int[] { 15, 10, 3 }, new int[] { 120, 45, 10, 3 } };
            var order = SortOrder.Descending;
            int[][] expected = { new int[] { 15, 11, 5 }, new int[] { 120, 46, 12, 6 } };
            //Act & Assert 
            for (int i = 0; i < expected.Length; i++)
            {
                CheckTransform(actual[i], order, expected[i]);
            }
        }


        [Test]
        public void TransformWithDescendingSortNotChangeArray()
        {
            //Arrange      
            int[][] actual = { new int[] { 5, 10, 7 }, new int[] { 1, 100, 17, 27, 6 } };
            var order = SortOrder.Descending;
            int[][] expected = { new int[] { 5, 10, 7 }, new int[] { 1, 100, 17, 27, 6 } };

            //Act & Assert 
            for (int i = 0; i < actual.Length; i++)
            {
                CheckTransform(actual[i], order, expected[i]);
            }
        }
        #endregion


        #region IsSorted
        [Test]
        public void IsSortedWithAscendingSortReturnTrue()
        {
            //Arrange 
            int[][] actual = { new int[] { 15, 20, 100, 123, 200, 666 }, new int[] { 15, 20, 100, 123, 200, 666 } };
            var order = SortOrder.Ascending;
            bool expected = true;
            //Act & Assert 
            for (int i = 0; i < actual.Length; i++)
            {
                CheckIsSorted(actual[i], order, expected);
            }
        }


        [Test]
        public void IsSortedWithAscendingSortReturnFalse()
        {
            //Arrange 
            int[][] actual = { new int[] { 10, 6, 1, 11, 7, 9 }, new int[] { 10, 6, 1, 11, 7, 9 } };
            var order = SortOrder.Ascending;
            bool expected = false;
            //Act & Assert 
            for (int i = 0; i < actual.Length; i++)
            {
                CheckIsSorted(actual[i], order, expected);
            }

        }


        [Test]
        public void IsSortedWithDescendingSortReturnTrue()
        {
            //Arrange 
            int[][] actual = { new int[] { 20, 7, 3, 2, 1, 0 }, new int[] { 130, 25, 21, 9, 3, 0 } };
            var order = SortOrder.Descending;
            bool expected = true;
            //Act & Assert 
            for (int i = 0; i < actual.Length; i++)
            {
                CheckIsSorted(actual[i], order, expected);
            }

        }


        [Test]
        public void IsSortedWithDescendingSortReturnFalse()
        {
            //Arrange 
            int[][] actual = { new int[] { 5, 8, 2, 1, 0, 12 }, new int[] { 120, 50, 35, 55 } };
            var order = SortOrder.Descending;
            bool expected = false;
            //Act & Assert 
            for (int i = 0; i < actual.Length; i++)
            {
                CheckIsSorted(actual[i], order, expected);
            }

        }
        #endregion

        #region MultArithmeticElements
        [Test]
        public void MultArithmeticElementsReturnCorrectValue()
        {
            //Arrange 
            double[] a = new double[2] { 5, 10.5 };
            double[] t = new double[2] { 3, 8 };
            int[] n = new int[2] { 4, 3 };
            double[] expected = new double[2] { 6160, 5147.625 };
            //Act & Assert 
            for (int i = 0; i < expected.Length; i++)
            {
                CheckMult(a[i], t[i], n[i], expected[i]);
            }

        }


        [Test]
        public void MultArithmeticElementsReturnCorrectValue2()
        {
            //Arrange 
            double[] a = new double[2] { -8, 4 };
            double[] t = new double[2] { 3.5, -4 };
            int[] n = new int[2] { 5, 4 };
            double[] expected = new double[2] { -540, 0 };
            //Act & Assert 
            for (int i = 0; i < expected.Length; i++)
            {
                CheckMult(a[i], t[i], n[i], expected[i]);
            }

        }
        #endregion

        #region SumGeometricElements
        [Test]

        public void SumGeometricElementsReturnCorrectValue()
        {
            //Arrange
            double[] a = new double[2] { 100, 30 };
            double[] t = new double[2] { 0.5, 0.3 };
            double[] alim = new double[2] { 20, 5 };
            double[] expected = new double[2] { 175, 39 };

            //Act & Assert 
            for (int i = 0; i < expected.Length; i++)
            {
                CheckSum(a[i], t[i], alim[i], expected[i]);
            }

        }
        

        [Test]
        public void SumGeometricElementsWithInvalidFirstParameterReturnZero()
        {
            //Arrange
            double[] a = new double[2] { 10, 56 };
            double[] t = new double[2] { 0.7, 0.9 };
            double[] alim = new double[2] { 15, 123 };
            double[] expected = new double[2] { 0, 0 };

            //Act & Assert 
            for (int i = 0; i < expected.Length; i++)
            {
                CheckSum(a[i], t[i], alim[i], expected[i]);
            }

        }
        #endregion

        #endregion
    }
}
