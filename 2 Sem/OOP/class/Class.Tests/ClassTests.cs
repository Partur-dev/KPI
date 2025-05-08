using System;
using System.Collections.Generic;
using System.Reflection;
using NUnit.Framework;

namespace Class.Tests
{
    [TestFixture]
    public class ClassTests
    {
        private static Type GetRectangleType()
        {
            var type = Type.GetType("Class.Rectangle" + ", Class");

            AssertFailIfNull(type, "Class 'Rectangle'");

            return type;
        }

        private static object GetRectangleInstance(params object[] args)
        {
            var type = GetRectangleType();

            var rectangle = Activator.CreateInstance(type, args);

            AssertFailIfNull(rectangle, "Class 'Rectangle'");

            return rectangle;
        }

        private static Type GetArrayRectanglesType()
        {
            var type = Type.GetType("Class.ArrayRectangles" + ", Class");

            AssertFailIfNull(type, "Class 'ArrayRectangles'");

            return type;
        }

        private static object GetArrayRectanglesInstance(params object[] args)
        {
            var type = GetArrayRectanglesType();

            var rectangle = Activator.CreateInstance(type, args);

            AssertFailIfNull(rectangle, "Class 'ArrayRectangles'");

            return rectangle;
        }

        private static void AssertFailIfNull(object obj, string message)
        {
            if (obj == null)
            {
                Assert.Fail($"{message} doesn't exist");
            }
        }

        [TestCase("Rectangle")]
        [TestCase("ArrayRectangles")]
        public void ClassExists(string className)
        {
            var type = Type.GetType($"Class.{className}" + ", Class");

            if (type == null && !type.IsPublic)
                Assert.Fail($"Class '{className}' doesn't exist.");
        }

        [TestCase("Rectangle", typeof(double), typeof(double))]
        [TestCase("Rectangle", typeof(double))]
        [TestCase("Rectangle")]
        [TestCase("ArrayRectangles", typeof(int))]
        [TestCase("ArrayRectangles", typeof(int))]
        public void ClassHasPublicConstructor(string className, params Type[] parameters)
        {
            var type = Type.GetType($"Class.{className}" + ", Class");

            if (type == null)
            {
                Assert.Fail($"Class '{className}' doesn't exist.");
            }

            var constructor = type.GetConstructor(parameters);

            if (constructor == null && !constructor.IsPublic)
                Assert.Fail($"Class '{className}' doesn't have public constructor.");
        }

        [TestCase("Rectangle", "sideA")]
        [TestCase("Rectangle", "sideB")]
        [TestCase("ArrayRectangles", "rectangle_array")]
        public void ClassHasPrivateField(string className, string fieldName)
        {
            var type = Type.GetType($"Class.{className}" + ", Class");

            if (type == null)
            {
                Assert.Fail($"Class '{className}' doesn't exist.");
            }

            var field = type.GetField(fieldName, BindingFlags.NonPublic | BindingFlags.Instance);

            if (field == null && !field.IsPrivate)
                Assert.Fail($"Class '{className}' doesn't have private field with name '{fieldName}'.");
        }


        static readonly object[] addRectangleTestSource =
        {
            new object[]
                {"ArrayRectangles", "AddRectangle", typeof(bool), new Type[] {Type.GetType("Class.Rectangle, Class")}}
        };


        [TestCase("Rectangle", "GetSideA", typeof(double))]
        [TestCase("Rectangle", "GetSideB", typeof(double))]
        [TestCase("Rectangle", "Area", typeof(double))]
        [TestCase("Rectangle", "Perimeter", typeof(double))]
        [TestCase("Rectangle", "IsSquare", typeof(bool))]
        [TestCase("Rectangle", "ReplaceSides", typeof(void))]
        [TestCase("ArrayRectangles", "NumberMaxArea", typeof(int))]
        [TestCase("ArrayRectangles", "NumberMinPerimeter", typeof(int))]
        [TestCase("ArrayRectangles", "NumberSquare", typeof(int))]
        [TestCaseSource(nameof(addRectangleTestSource))]
        public void ClassHasPublicMethodWithCorrectSignature(string className, string methodName, Type returnType,
            params Type[] parameters)
        {
            var type = Type.GetType($"Class.{className}" + ", Class");

            if (type == null)
            {
                Assert.Fail($"Class '{className}' doesn't exist.");
            }

            var method = type.GetMethod(methodName, parameters);

            if (method == null && !method.IsPublic && method.ReturnType != returnType)
                Assert.Fail($"Class '{className}' doesn't have method with name '{methodName}' that returns {returnType}.");
        }

        [TestCase(5, 5)]
        [TestCase(2.28, 1234)]
        [TestCase(13.37, 14.89)]
        public void RectangleGetSideAWithConstructorThatTakes2ParametersReturnsCorrectValue(double sideA, double sideB)
        {
            var expectedSideA = sideA;
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exist.");
            }

            var rectangle = Activator.CreateInstance(type, sideA, sideB);

            var GetSideA = type.GetMethod("GetSideA");
            AssertFailIfNull(GetSideA, "Method 'GetSideA'");

            if (expectedSideA != (double)GetSideA.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'GetSideA' in rectangle that has constructor with 2 arguments works incorrectly.");

            }
        }
        
        [TestCase(5, 5)]
        [TestCase(2.28, 1234)]
        [TestCase(13.37, 14.89)]
        public void RectangleGetSideBWithConstructorThatTakes2ParametersReturnsCorrectValue(double sideA, double sideB)
        {
            var expectedSideB = sideB;
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exist.");
            }

            var rectangle = Activator.CreateInstance(type, sideA, sideB);

            var GetSideB = type.GetMethod("GetSideB");
            AssertFailIfNull(GetSideB, "Method 'GetSideB'");

            if (expectedSideB != (double)GetSideB.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'GetSideB' in rectangle that has constructor with 2 arguments works incorrectly.");
            }
        }
        
        [TestCase(5, 5)]
        [TestCase(2.28, 5)]
        [TestCase(13.37, 5)]
        public void RectangleGetSideAWithConstructorThatTakes1ParameterReturnsCorrectValue(double sideA, double sideB)
        {
            var expectedSideA = sideA;
            
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exist.");
            }

            var rectangle = Activator.CreateInstance(type, sideA);

            var GetSideA = type.GetMethod("GetSideA");
            AssertFailIfNull(GetSideA, "Method 'GetSideA'");

            if (expectedSideA != (double)GetSideA.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'GetSideA' in rectangle that has constructor with 1 argument works incorrectly.");
            }
        }
        
        [TestCase(5, 5)]
        [TestCase(2.28, 5)]
        [TestCase(13.37, 5)]
        public void RectangleGetSideBWithConstructorThatTakes1ParameterReturnsCorrectValue(double sideA, double sideB)
        {
            var expectedSideB = sideB;
            
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exist.");
            }

            var rectangle = Activator.CreateInstance(type, sideA);

            var GetSideB = type.GetMethod("GetSideB");
            AssertFailIfNull(GetSideB, "Method 'GetSideB'");

            if (expectedSideB != (double)GetSideB.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'GetSideB' in rectangle that has constructor with 1 argument works incorrectly.");
            }
        }
        
        [TestCase(4, 3)]
        public void RectangleGetSideAWithConstructorThatTakes0ParametersReturnsCorrectValue(double sideA, double sideB)
        {
            var expectedSideA = sideA;
            
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exist.");
            }

            var rectangle = Activator.CreateInstance(type);

            var GetSideA = type.GetMethod("GetSideA");
            AssertFailIfNull(GetSideA, "Method 'GetSideA'");

            if (expectedSideA != (double)GetSideA.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'GetSideA' in rectangle that has constructor with 0 arguments works incorrectly.");
            }
        }
        
        [TestCase(4, 3)]
        public void RectangleGetSideBWithConstructorThatTakes0ParametersReturnsCorrectValue(double sideA, double sideB)
        {
            var expectedSideB = sideB;
            
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exist.");
            }

            var rectangle = Activator.CreateInstance(type);

            var GetSideB = type.GetMethod("GetSideB");
            AssertFailIfNull(GetSideB, "Method 'GetSideB'");

            if (expectedSideB != (double)GetSideB.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'GetSideB' in rectangle that has constructor with 0 arguments works incorrectly.");
            }
        }

        #region Advanced        
        
        
        [TestCase(5, 5, 25)]
        [TestCase(2, 2, 4)]
        [TestCase(0.5, 0.5, 0.25)]
        public void RectangleAreaReturnsCorrectValue(double sideA, double sideB, double result)
        {
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exist.");
            }

            var rectangle = Activator.CreateInstance(type, sideA, sideB);

            var Area = type.GetMethod("Area");
            AssertFailIfNull(Area, "Method 'Area'");

            if (result != (double)Area.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'Area' in rectangle works incorrectly.");
            }
        }

        [TestCase(5, 5)]
        [TestCase(1, 2)]
        [TestCase(1, 1)]
        public void RectanglePerimeterReturnsCorrectValue(double sideA, double sideB)
        {
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exists.");
            }

            var result = (sideA + sideB) * 2;

            var rectangle = Activator.CreateInstance(type, sideA, sideB);

            var Perimeter = type.GetMethod("Perimeter");
            AssertFailIfNull(Perimeter, "Method 'Perimeter'");


            if (result != (double)Perimeter.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'Perimeter' in rectangle works incorrectly.");
            }
        }

        [TestCase(5, 5, true)]
        [TestCase(2, 2, true)]
        [TestCase(2, 28, false)]
        [TestCase(14, 88, false)]
        public void RectangleIsSquareReturnsCorrectValue(double sideA, double sideB, bool result)
        {
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exists.");
            }

            var rectangle = Activator.CreateInstance(type, sideA, sideB);

            var IsSquare = type.GetMethod("IsSquare");
            AssertFailIfNull(IsSquare, "Method 'IsSquare'");


            if (result != (bool)IsSquare.Invoke(rectangle, null))
            {
                Assert.Fail("Method 'IsSquare' in rectangle works incorrectly.");
            }
        }

        [TestCase(1, 5)]
        [TestCase(1, 2)]
        [TestCase(2, 3)]
        public void RectangleReplaceSidesSwitchSides(double sideA, double sideB)
        {
            var type = Type.GetType("Class.Rectangle" + ", Class");

            if (type == null)
            {
                Assert.Fail("Class 'Rectangle' doesn't exist.");
            }

            var rectangle = Activator.CreateInstance(type, sideA, sideB);

            var ReplaceSides = type.GetMethod("ReplaceSides");
            AssertFailIfNull(ReplaceSides, "Method 'ReplaceSides'");

            ReplaceSides.Invoke(rectangle, null);

            var rectangleSideA = type.GetField("sideA", BindingFlags.NonPublic | BindingFlags.Instance);
            var rectangleSideB = type.GetField("sideB", BindingFlags.NonPublic | BindingFlags.Instance);

            if (rectangleSideA != null && rectangleSideA.IsPrivate && rectangleSideB != null && rectangleSideB.IsPrivate)
            {
                if (sideA != (double) rectangleSideB.GetValue(rectangle) &&
                    sideB != (double) rectangleSideA.GetValue(rectangle))
                {
                    Assert.Fail("Method 'ReplaceSides' in rectangle works incorrectly.");
                }
            }
        }

        [TestCase(2)]
        [TestCase(4)]
        [TestCase(10)]
        public void ArrayRectanglesConstructorThatTakesIntAssignsCorrectValueToField(int length)
        {
            var arrRectType = GetArrayRectanglesType();

            var arrayRectangles = GetArrayRectanglesInstance(length);

            var arrayInfo = arrRectType.GetField("rectangle_array", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(arrayInfo, "Field 'rectangle_array'");


            var objArray = (Array)arrayInfo.GetValue(arrayRectangles);


            if (objArray.Length != length)
                Assert.Fail("Constructor in 'ArrayRectangles' works incorrectly.");
        }

        [Test]
        public void ArrayRectanglesConstructorThatTakesEnumerableOrArrayAssignsCorrectValueToField()
        {
            var arrayRectanglesType = GetArrayRectanglesType();
            var rectangleType = GetRectangleType();

            var arrayType = Array.CreateInstance(rectangleType, 1).GetType();
            var enumerableType = typeof(IEnumerable<>).MakeGenericType(rectangleType);

            var enumerableConstructor = arrayRectanglesType.GetConstructor(new Type[] { enumerableType });
            var arrayConstructor = arrayRectanglesType.GetConstructor(new Type[] { arrayType });

            var arrayInfo = arrayRectanglesType.GetField("rectangle_array", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(arrayInfo, "Field 'rectangle_array'");

            object arrayRectangles;
            object rectanglesCollection;
            if (arrayConstructor != null)
            {
                var array = Array.CreateInstance(rectangleType, 10);
                arrayRectangles = arrayConstructor.Invoke(new object[] { array });
                rectanglesCollection = array;
            }
            else if (enumerableConstructor != null)
            {
                var enumerable = Activator.CreateInstance(typeof(List<>).MakeGenericType(rectangleType));
                arrayRectangles = enumerableConstructor.Invoke(new object[] { enumerable });
                rectanglesCollection = enumerable;
            }
            else
            {
                Assert.Fail("There is no constructor in 'ArrayRectangles' that takes IEnumerable or array of rectangles");
                return;
            }


            var arrayField = (Array)arrayInfo.GetValue(arrayRectangles);
            var rectanglesCollectionAsArray = (Array)rectanglesCollection;


            for (int i = 0; i < arrayField.Length; i++)
            {
                if (arrayField.GetValue(i) != rectanglesCollectionAsArray.GetValue(i))
                    Assert.Fail("Constructor in 'ArrayRectangles' works incorrectly.");
            }
        }

        [TestCase(1)]
        [TestCase(5)]
        [TestCase(7)]
        [TestCase(0)]
        public void ArrayRectanglesAddRectangleAddsRectangleOnFirstFreePlace(int addCount)
        {
            //arrange
            var arrRectType = GetArrayRectanglesType();
            var rectangleType = GetRectangleType();

            var arrayRectangles = GetArrayRectanglesInstance(10);
            var rectangle = GetRectangleInstance();

            var arrayInfo = arrRectType.GetField("rectangle_array", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(arrayInfo, "Field 'rectangle_array'");

            var method = arrRectType.GetMethod("AddRectangle");
            AssertFailIfNull(method, "Method 'AddRectangle'");

            //act
            for (int i = 0; i < addCount; i++)
            {
                method.Invoke(arrayRectangles, new object[] { rectangle });
            }

            var objArray = (Array)arrayInfo.GetValue(arrayRectangles);
            var array = Array.CreateInstance(rectangleType, 10);
            Array.Copy(objArray, array, 10);

            //assert
            for (int i = 0; i < array.Length; i++)
            {
                if ((i < addCount && array.GetValue(i) == null)
                    || (i >= addCount && array.GetValue(i) != null))
                {
                    Assert.Fail("Method 'AddRectangle' in ArrayRectangles works incorrectly.");
                }
            }
        }

        [Test]
        public void ArrayRectanglesAddRectangleReturnsTrueIfArrayHasFreePlace()
        {
            //arrange
            var arrRectType = GetArrayRectanglesType();

            var arrayRectangles = GetArrayRectanglesInstance(10);
            var rectangle = GetRectangleInstance();

            var method = arrRectType.GetMethod("AddRectangle");
            AssertFailIfNull(method, "Method 'AddRectangle'");

            //act
            var hasFreePlace = (bool)method.Invoke(arrayRectangles, new object[] { rectangle });

            //assert
            if (!hasFreePlace)
                Assert.Fail("Method 'AddRectangle' in ArrayRectangles works incorrectly.");

        }

        [Test]
        public void ArrayRectanglesAddRectangleReturnsFalseIfArrayHasNotFreePlace()
        {
            //arrange
            var arrRectType = GetArrayRectanglesType();

            var arrayRectangles = GetArrayRectanglesInstance(0);
            var rectangle = GetRectangleInstance();

            var method = arrRectType.GetMethod("AddRectangle");
            AssertFailIfNull(method, "Method 'AddRectangle'");

            //act
            var hasFreePlace = (bool)method.Invoke(arrayRectangles, new object[] { rectangle });

            //assert
            if (hasFreePlace)
                Assert.Fail("Method 'AddRectangle' in ArrayRectangles works incorrectly.");
        }

        [Test]
        public void ArrayRectanglesNumberMaxAreaReturnsCorrectValue()
        {
            //arrange
            var arrRectType = GetArrayRectanglesType();
            
            var addRectangle = arrRectType.GetMethod("AddRectangle");
            AssertFailIfNull(addRectangle, "Method 'AddRectangle'");

            var rectangle1 = GetRectangleInstance(2, 2);
            var rectangle2 = GetRectangleInstance(10, 8);
            var rectangle3 = GetRectangleInstance(5, 5);
            
            var rectangle_array = arrRectType.GetField("rectangle_array", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(rectangle_array, "Field 'rectangle_array'");

            var arrayRectangles = GetArrayRectanglesInstance(3);
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle1 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle2 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle3 });

            var method = arrRectType.GetMethod("NumberMaxArea");
            AssertFailIfNull(method, "Method 'NumberMaxArea'");

            //act
            var result = (int)method.Invoke(arrayRectangles, null);

            //assert
            if (result != 1)
                Assert.Fail("Method 'NumberMaxArea' in ArrayRectangles works incorrectly.");
        }

        [Test]
        public void ArrayRectanglesNumberMinPerimeterReturnsCorrectValue()
        {
            //arrange
            var arrRectType = GetArrayRectanglesType();

            var addRectangle = arrRectType.GetMethod("AddRectangle");
            AssertFailIfNull(addRectangle, "Method 'AddRectangle'");
            
            var rectangle1 = GetRectangleInstance(5, 5);
            var rectangle2 = GetRectangleInstance(10, 8);
            var rectangle3 = GetRectangleInstance(2, 3);
            
            var rectangle_array = arrRectType.GetField("rectangle_array", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(rectangle_array, "Field 'rectangle_array'");

            var arrayRectangles = GetArrayRectanglesInstance(3);
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle1 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle2 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle3 });

            var method = arrRectType.GetMethod("NumberMinPerimeter");
            AssertFailIfNull(method, "Method 'NumberMinPerimeter'");

            //act
            var result = (int)method.Invoke(arrayRectangles, null);

            //assert
            if (result != 2)
                Assert.Fail("Method 'NumberMinPerimeter' in ArrayRectangles works incorrectly.");
        }

        [Test]
        public void ArrayRectanglesNumberSquareReturnsCorrectValue()
        {
            //arrange
            var arrRectType = GetArrayRectanglesType();

            var addRectangle = arrRectType.GetMethod("AddRectangle");
            AssertFailIfNull(addRectangle, "Method 'AddRectangle'");

            var rectangle1 = GetRectangleInstance(2, 3);
            var rectangle2 = GetRectangleInstance(10, 8);
            var rectangle3 = GetRectangleInstance(5, 5);
            var rectangle4 = GetRectangleInstance(8, 8);
            var rectangle5 = GetRectangleInstance(4, 4);
            var rectangle6 = GetRectangleInstance(5, 5);

            var arrayRectangles = GetArrayRectanglesInstance(6);
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle1 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle2 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle3 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle4 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle5 });
            addRectangle.Invoke(arrayRectangles, new object[] { rectangle6 });

            var method = arrRectType.GetMethod("NumberSquare");
            AssertFailIfNull(method, "Method 'NumberSquare'");

            //act
            var result = (int)method.Invoke(arrayRectangles, null);

            //assert
            if (result != 4)
                Assert.Fail("Method 'NumberSquare' in ArrayRectangles works incorrectly.");
        }
        
        #endregion
    }
}