using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using NUnit.Framework;
using Interfaces;

namespace Interfaces.Tests
{
    [TestFixture]
    public class Tests
    {
        const string AssemblyName = "Interfaces";

        private static void AssertFailIfNull(object obj, string message)
        {
            if (obj == null)
            {
                Assert.Fail($"{message} doesn't exist");
            }
        }

        private static Type GetCustomType(string name, string message)
        {
            var type = Type.GetType($"{AssemblyName}.{name}, {AssemblyName}");
            AssertFailIfNull(type, message);
            return type;
        }

        [TestCase("BaseDeposit", 1000, 0, 0)]
        [TestCase("BaseDeposit", 1000, 1, 50)]
        [TestCase("BaseDeposit", 1000, 2, 102.5)]
        [TestCase("BaseDeposit", 1000, 3, 157.625)]
        [TestCase("SpecialDeposit", 1000, 0, 0)]
        [TestCase("SpecialDeposit", 1000, 1, 10)]
        [TestCase("SpecialDeposit", 1000, 2, 30.2)]
        [TestCase("SpecialDeposit", 1000, 3, 61.106)]
        [TestCase("LongDeposit", 1000, 0, 0)]
        [TestCase("LongDeposit", 1000, 1, 0)]
        [TestCase("LongDeposit", 1000, 6, 0)]
        [TestCase("LongDeposit", 1000, 7, 150)]
        [TestCase("LongDeposit", 1000, 8, 322.5)]
        public void ClassIncomeWorksCorrectly(string className, decimal summ, int period, decimal expectedAmountAfterPeriod)
        {
            var type = Type.GetType($"{AssemblyName}.{className}, {AssemblyName}");
            decimal precision = 0.01m;
            AssertFailIfNull(type, $"Class '{className}'");

            var income = type.GetMethod("Income");
            AssertFailIfNull(income, "Method 'Income'");

            var deposit = Activator.CreateInstance(type, summ, period);

            if (Math.Abs(expectedAmountAfterPeriod - (decimal)income.Invoke(deposit, null)) > precision)
            {
                Assert.Fail($"Method 'Income' in {className} class works incorrectly.");
            }
        }

        [Test]
        public void DepositIsAbstractClassOrExists()
        {
            var type = Type.GetType($"{AssemblyName}.Deposit, {AssemblyName}");

            AssertFailIfNull(type, "Class 'Deposit'");

            if (!type.IsAbstract)
            {
                Assert.Fail("Class 'Deposit' is not abstract.");
            }
        }

        [TestCase("Deposit")]
        [TestCase("BaseDeposit")]
        [TestCase("SpecialDeposit")]
        [TestCase("LongDeposit")]
        [TestCase("Client")]
        public void ClassIsClassExists(string className)
        {
            var type = Type.GetType($"{AssemblyName}.{className}, {AssemblyName}");

            AssertFailIfNull(type, $"Class '{className}'");
        }

        [TestCase("Deposit", "BaseDeposit")]
        [TestCase("Deposit", "SpecialDeposit")]
        [TestCase("Deposit", "LongDeposit")]
        public void ClassIsClassInheritsFromClass(string parentClassName, string childClassName)
        {
            var parentType = Type.GetType($"{AssemblyName}.{parentClassName}, {AssemblyName}");
            var childType = Type.GetType($"{AssemblyName}.{childClassName}, {AssemblyName}");

            AssertFailIfNull(parentType, $"Class '{parentClassName}'");
            AssertFailIfNull(childType, $"Class '{childClassName}'");

            if (!parentType.IsAbstract && !childType.IsSubclassOf(parentType))
            {
                Assert.Fail($"Class '{childType}' doesn't inherit from '{parentType}'");
            }
        }

        [TestCase("Deposit", "Income", typeof(decimal))]
        [TestCase("BaseDeposit", "Income", typeof(decimal))]
        [TestCase("SpecialDeposit", "Income", typeof(decimal))]
        [TestCase("LongDeposit", "Income", typeof(decimal))]
        [TestCase("Client", "AddDeposit", typeof(bool))]
        [TestCase("Client", "TotalIncome", typeof(decimal))]
        [TestCase("Client", "MaxIncome", typeof(decimal))]
        [TestCase("Client", "GetIncomeByNumber", typeof(decimal))]
        public void ClassHasMethodsWithCorrectSignatures(string className, string methodName, Type returnType)
        {
            var classType = Type.GetType($"{AssemblyName}.{className}, {AssemblyName}");
            AssertFailIfNull(classType, $"Class '{className}'");

            var methodType = classType.GetMethod(methodName);
            AssertFailIfNull(methodType, $"Method '{methodName}'");

            if (methodType.ReturnType != returnType)
            {
                Assert.Fail($"Class '{className}' doesn't have method with name '{methodName}' that returns '{returnType}'.");
            }
        }

        [Test]
        public void DepositHasAbstractMethodIncome()
        {
            var classType = Type.GetType($"{AssemblyName}.Deposit, {AssemblyName}");
            AssertFailIfNull(classType, $"Class 'Deposit'");

            var methodType = classType.GetMethod("Income");
            AssertFailIfNull(methodType, $"Method 'Income'");

            if (!methodType.IsAbstract)
            {
                Assert.Fail("Method 'Income' is not abstract.");
            }
        }

        [TestCase("Deposit", "Amount", typeof(decimal))]
        [TestCase("BaseDeposit", "Amount", typeof(decimal))]
        [TestCase("SpecialDeposit", "Amount", typeof(decimal))]
        [TestCase("LongDeposit", "Amount", typeof(decimal))]
        [TestCase("Deposit", "Period", typeof(int))]
        [TestCase("BaseDeposit", "Period", typeof(int))]
        [TestCase("SpecialDeposit", "Period", typeof(int))]
        [TestCase("LongDeposit", "Period", typeof(int))]
        public void ClassHasPublicReadonlyFieldWithType(string className, string fieldName, Type returnType)
        {
            var classType = Type.GetType($"{AssemblyName}.{className}, {AssemblyName}");
            AssertFailIfNull(classType, $"Class {className}");

            var propertyInfo = classType.GetProperty(fieldName, BindingFlags.Public | BindingFlags.Instance);
            AssertFailIfNull(propertyInfo, $"Field '{fieldName}'");

            if (!propertyInfo.CanRead && propertyInfo.CanWrite && propertyInfo.PropertyType != returnType)
            {
                Assert.Fail($"{className} doesn't have public readonly property {fieldName} with {returnType} return type.");
            }
        }

        [Test]
        public void ClientHasPrivatePropertyDeposits()
        {
            var client = GetCustomType("Client", "Class 'Client'");
            var deposit = GetCustomType("Deposit", "Class 'Deposit'");

            var fieldType = client.GetField("deposits", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(fieldType, "Field 'deposits'");

            var arrayOfDeposits = Array.CreateInstance(deposit, 10).GetType();

            if (!fieldType.IsPrivate && fieldType.FieldType != arrayOfDeposits)
            {
                Assert.Fail("Property 'deposits' in class 'Client' is incorrect.");
            }
        }

        [Test]
        public void ClientConstructorCreatesArrayOfDepositsWithSize10()
        {
            var client = GetCustomType("Client", "Class 'Client'");
            var deposit = GetCustomType("Deposit", "Class 'Deposit'");

            var fieldType = client.GetField("deposits", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(fieldType, "Field 'deposits'");

            var constructor = client.GetConstructor(Type.EmptyTypes);
            AssertFailIfNull(constructor, "Constructor of 'Client'");

            var invokedConstructor = constructor.Invoke(Type.EmptyTypes);
            var depositsField = (Array)fieldType.GetValue(invokedConstructor);
            AssertFailIfNull(depositsField, "Field 'deposits'");
            var arrayOfDeposits = Array.CreateInstance(deposit, 10);

            if (depositsField.Length != 10)
            {
                Assert.Fail("Property 'deposits' must be of type array of deposits with length 10.");
            }

            for (int i = 0; i < depositsField.Length; i++)
            {
                if (depositsField.GetValue(i) != arrayOfDeposits.GetValue(i))
                {
                    Assert.Fail("Constructor in class 'Client' works incorrectly.");
                }
            }
        }

        [TestCase("Deposit", typeof(decimal), typeof(int))]
        public void BaseClassDoesHaveConstructor(string className, params Type[] parameters)
        {
            var type = Type.GetType($"{AssemblyName}.{className}, {AssemblyName}");
            AssertFailIfNull(type, $"Class '{className}'");
            var constructor = type.GetConstructor(BindingFlags.NonPublic | BindingFlags.Instance, parameters);
            if (constructor == null && constructor.IsPublic)
            {
                Assert.Fail($"Class {className} has invalid constructor.");
            }
        }

        [TestCase("BaseDeposit", typeof(decimal), typeof(int))]
        [TestCase("SpecialDeposit", typeof(decimal), typeof(int))]
        [TestCase("LongDeposit", typeof(decimal), typeof(int))]
        [TestCase("Client")]
        public void ClassDoesHaveConstructor(string className, params Type[] parameters)
        {
            var type = Type.GetType($"{AssemblyName}.{className}, {AssemblyName}");

            AssertFailIfNull(type, $"Class '{className}'");

            var constructor = type.GetConstructor(parameters);

            if (constructor == null && !constructor.IsPublic)
            {
                Assert.Fail($"Class {className} has invalid constructor.");
            }
        }
        
        [TestCase(1, "BaseDeposit", typeof(decimal), typeof(int))]
        [TestCase(5, "LongDeposit", typeof(decimal), typeof(int))]
        [TestCase(7, "SpecialDeposit", typeof(decimal), typeof(int))]
        [TestCase(0, "BaseDeposit", typeof(decimal), typeof(int))]
        public void ClientAddDepositAddsObjectToFirstFreePlace(int addCount, string className, params Type[] parameters)
        {
            var clientType = GetCustomType("Client", "Class 'Client'");
            var deposit = GetCustomType(className, $"Class '{className}'");

            var clientObject = Activator.CreateInstance(clientType);
            
            var constructor = deposit.GetConstructor(parameters);
            AssertFailIfNull(constructor, $"Constructor in class '{className}'");

            if (constructor == null && !constructor.IsPublic)
            {
                Assert.Fail($"Constructor of class '{className}' doesn't exist.");
            }
            var depositObject = Activator.CreateInstance(deposit, 1000m, 1);

            var depositField = clientType.GetField("deposits", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(depositField, "Field 'deposits'");

            var method = clientType.GetMethod("AddDeposit");
            AssertFailIfNull(method, "Method 'AddDeposit'");

            for (int i = 0; i < addCount; i++)
            {
                method.Invoke(clientObject, new object[] {depositObject});
            }

            var objArray = (Array) depositField.GetValue(clientObject);
            var array = Array.CreateInstance(deposit, 10);
            Array.Copy(objArray, array, 10);

            for (int i = 0; i < array.Length; i++)
            {
                if ((i < addCount && array.GetValue(i) == null)
                    || (i > addCount && array.GetValue(i) != null))
                {
                    Assert.Fail("Method 'AddDeposit' in class 'Client' works incorrectly.");
                }
            }
        }

        [TestCase("BaseDeposit")]
        [TestCase("LongDeposit")]
        [TestCase("SpecialDeposit")]
        [TestCase("BaseDeposit")]
        public void ClientAddDepositReturnsTrueIfArrayHasFreePlace(string className)
        {
            //arrange
            var clientType = GetCustomType("Client", "Class 'Client'");
            var deposit = GetCustomType(className, $"Class '{className}'");

            var clientObject = Activator.CreateInstance(clientType);
            var depositObject = Activator.CreateInstance(deposit, 1000m, 1);

            var method = clientType.GetMethod("AddDeposit");
            AssertFailIfNull(method, "Method 'AddDeposit'");

            //act
            var hasFreePlace = (bool) method.Invoke(clientObject, new object[] {depositObject});

            //assert
            if (!hasFreePlace)
            {
                Assert.Fail("Method 'AddDeposit' in class 'Client' works incorrectly.");
            }
        }

        [TestCase("BaseDeposit")]
        [TestCase("LongDeposit")]
        [TestCase("SpecialDeposit")]
        [TestCase("BaseDeposit")]
        public void ClientAddDepositReturnsFalseIfArrayHasNoFreePlace(string className)
        {
            //arrange
            var clientType = GetCustomType("Client", "Class 'Client'");
            var deposit = GetCustomType(className, $"Class '{className}'");

            var clientObject = Activator.CreateInstance(clientType);
            var depositObject = Activator.CreateInstance(deposit, 1000m, 1);

            var method = clientType.GetMethod("AddDeposit");
            AssertFailIfNull(method, "Method 'AddDeposit'");

            //act
            for (int i = 0; i < 10; i++)
            {
                method.Invoke(clientObject, new object[] {depositObject});
            }

            var hasFreePlace = (bool) method.Invoke(clientObject, new object[] {depositObject});

            //assert
            if (hasFreePlace)
            {
                Assert.Fail("Method 'AddDeposit' in class 'Client' works incorrectly.");
            }
        }

        [TestCase("BaseDeposit", 1000, 1, 50 * 5)]
        [TestCase("LongDeposit", 1000, 7, 150 * 5)]
        [TestCase("SpecialDeposit", 1000, 1, 10 * 5)]
        public void ClientTotalIncomeReturnsSumOfIncomeOfAllDeposits(string className, decimal amount, int period,
            decimal expectedIncome)
        {
            //arrange
            var clientType = GetCustomType("Client", "Class 'Client'");
            var deposit = GetCustomType(className, $"Class '{className}'");

            var clientObject = Activator.CreateInstance(clientType);
            var depositObject = Activator.CreateInstance(deposit, amount, period);

            var AddDepositMethod = clientType.GetMethod("AddDeposit");
            AssertFailIfNull(AddDepositMethod, "Method 'AddDeposit'");

            //act
            for (int i = 0; i < 5; i++)
            {
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject});
            }

            var TotalIncomeMethod = clientType.GetMethod("TotalIncome");
            AssertFailIfNull(TotalIncomeMethod, "Method 'TotalIncome'");

            decimal result = 0;

            try
            {
                result = (decimal) TotalIncomeMethod.Invoke(clientObject, Type.EmptyTypes);
            }
            catch
            {
                Assert.Fail("Method 'TotalIncome' should check if the element in 'deposits' is null");
            }

            if (expectedIncome != result)
            {
                Assert.Fail();
            }
        }

        [TestCase(
            "BaseDeposit", 1000, 1,
            "LongDeposit", 1000, 7,
            "SpecialDeposit", 1000, 1,
            150)]
        public void ClientMaxIncomeReturnsMaxIncomeOfAllDeposits(string className1, decimal amount1, int period1,
            string className2, decimal amount2, int period2, string className3, decimal amount3, int period3,
            decimal expectedMaxIncome)
        {
            //arrange
            var clientType = GetCustomType("Client", "Class 'Client'");
            var deposit1 = GetCustomType(className1, $"Class '{className1}'");
            var deposit2 = GetCustomType(className2, $"Class '{className2}'");
            var deposit3 = GetCustomType(className3, $"Class '{className3}'");

            var clientObject = Activator.CreateInstance(clientType);
            var depositObject1 = Activator.CreateInstance(deposit1, amount1, period1);
            var depositObject2 = Activator.CreateInstance(deposit2, amount2, period2);
            var depositObject3 = Activator.CreateInstance(deposit3, amount3, period3);

            var AddDepositMethod = clientType.GetMethod("AddDeposit");
            AssertFailIfNull(AddDepositMethod, "Method 'AddDeposit'");

            for (int i = 0; i < 3; i++)
            {
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject1});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject2});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject3});
            }

            var MaxIncomeMethod = clientType.GetMethod("MaxIncome");
            AssertFailIfNull(MaxIncomeMethod, "Method 'MaxIncome'");
            
            decimal result = 0;

            try
            {
                result = (decimal) MaxIncomeMethod.Invoke(clientObject, Type.EmptyTypes);
            }
            catch
            {
                Assert.Fail("Method 'MaxIncome' should check if the element in 'deposits' is null");
            }

            if (expectedMaxIncome != result)
            {
                Assert.Fail("Method 'MaxIncome' in class 'Client' works incorrectly.");
            }
        }

        [TestCase(
            "BaseDeposit", 1000, 1,
            "LongDeposit", 1000, 7,
            "SpecialDeposit", 1000, 1,
            150, 2)]
        public void ClientGetIncomeByNumberReturnsIncomeOfDepositWithIndexPlusOne(string className1, decimal amount1, int period1,
            string className2, decimal amount2, int period2, string className3, decimal amount3, int period3,
            int expectedIncome, int number)
        {
            //arrange
            var clientType = GetCustomType("Client", "Class 'Client'");
            var baseDeposit = GetCustomType(className1, $"Class '{className1}'");
            var longDeposit = GetCustomType(className2, $"Class '{className2}'");
            var specialDeposit = GetCustomType(className3, $"Class '{className3}'");

            var clientObject = Activator.CreateInstance(clientType);
            var depositObject1 = Activator.CreateInstance(baseDeposit, amount1, period1);
            var depositObject2 = Activator.CreateInstance(longDeposit, amount2, period2);
            var depositObject3 = Activator.CreateInstance(specialDeposit, amount3, period3);

            var AddDepositMethod = clientType.GetMethod("AddDeposit");
            AssertFailIfNull(AddDepositMethod, "Method 'AddDeposit'");

            //act
            void AddDeposits()
            {
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject1});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject2});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject3});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject1});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject2});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject3});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject1});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject2});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject3});
                AddDepositMethod.Invoke(clientObject, new object[] {depositObject3});
            }

            AddDeposits();

            var GetIncomeByNumber = clientType.GetMethod("GetIncomeByNumber");
            AssertFailIfNull(GetIncomeByNumber, "Method 'GetIncomeByNumber'");

            var result = (decimal) GetIncomeByNumber.Invoke(clientObject, new object[] {number});

            if (expectedIncome != result)
            {
                Assert.Fail("Method 'GetIncomeByNumber' in class 'Client' works incorrectly.");
            }
        }

        [TestCase(1)]
        [TestCase(2)]
        public void ClientGetIncomeByNumberReturns0IfDepositIsNull(int number)
        {
            var clientType = GetCustomType("Client", "Class 'Client'");
            var clientObject = Activator.CreateInstance(clientType);
            var GetIncomeByNumber = clientType.GetMethod("GetIncomeByNumber");
            AssertFailIfNull(GetIncomeByNumber, "Method 'GetIncomeByNumber'");

            var result = (decimal) GetIncomeByNumber.Invoke(clientObject, new object[] {number});
             
            if (result != 0)
            {
                Assert.Fail("Method 'GetIncomeByNumber' in class 'Client' works incorrectly.");
            }
        }

        // WARNING: The area below is allowed only for interfaces tests. If you cross it with abstract, you're gay

        [TestCase("IProlongable")]
        public void InterfaceExists(string name)
        {
            var type = Type.GetType($"{AssemblyName}.{name}, {AssemblyName}");

            if (type == null || !type.IsInterface)
            {
                Assert.Fail($"Interface '{name} doesn't exist'.");
            }
        }

        [TestCase("SpecialDeposit", "IProlongable")]
        [TestCase("LongDeposit", "IProlongable")]
        public void ClassImplementsCustomInterface(string className, string interfaceName)
        {
            var classType = Type.GetType($"{AssemblyName}.{className}, {AssemblyName}");
            var interfaceType = Type.GetType($"{AssemblyName}.{interfaceName}, {AssemblyName}");

            if (classType == null || !classType.IsClass)
            {
                Assert.Fail($"Class '{className}' doesn't exist");
            }

            if (interfaceType == null || !interfaceType.IsInterface)
            {
                Assert.Fail($"Interface '{interfaceName}' doesn't exist");
            }

            if (!classType.GetInterfaces().Contains(interfaceType))
            {
                Assert.Fail($"Class '{className}' doesn't implement interface '{interfaceName}'.");
            }
        }

        [TestCase("Deposit", typeof(IComparable<>), "Deposit")]
        [TestCase("Client", typeof(IEnumerable<>), "Deposit")]
        public void ClassImplementsLibraryGenericInterface(string className, Type interfaceType,
            string genericClassName)
        {
            var classType = Type.GetType($"{AssemblyName}.{className}, {AssemblyName}");
            var genericType = Type.GetType($"{AssemblyName}.{genericClassName}, {AssemblyName}");

            if (classType == null || !classType.IsClass)
            {
                Assert.Fail($"Class '{className}' doesn't exist");
            }

            if (genericType == null || !classType.IsClass)
            {
                Assert.Fail($"Class '{genericClassName}' doesn't exist");
            }

            var genericInterfaceType = interfaceType.MakeGenericType(genericType);

            if (!classType.GetInterfaces().Contains(genericInterfaceType))
            {
                Assert.Fail($"Class '{className}' doesn't implement interface '{genericInterfaceType.Name}'.");
            }
        }

        [TestCase("Client", "SortDeposits", typeof(void))]
        [TestCase("Client", "CountPossibleToProlongDeposit", typeof(int))]
        [TestCase("IProlongable", "CanToProlong", typeof(bool))]
        public void TypeHasMethod(string typeName, string methodName, Type returnType,
            params Type[] parameters)
        {
            var type = Type.GetType($"{AssemblyName}.{typeName}, {AssemblyName}");

            if (type == null)
            {
                Assert.Fail($"Type '{typeName}' doesn't exist.");
            }

            var method = type.GetMethod(methodName, parameters);

            if (method == null || method.ReturnType != returnType)
                Assert.Fail(
                    $"Type '{typeName}' doesn't have method with name '{methodName}' that returns {returnType}.");
        }

        [TestCase("LongDeposit", 40, 120, false)]
        [TestCase("LongDeposit", 40, 37, false)]
        [TestCase("LongDeposit", 40, 22, true)]
        [TestCase("LongDeposit", 40, 0, true)]
        [TestCase("SpecialDeposit", 40, 2, false)]
        [TestCase("SpecialDeposit", 1000, 2, false)]
        [TestCase("SpecialDeposit", 1020, 2, true)]
        [TestCase("SpecialDeposit", 2000, 2, true)]
        public void CanToProlongImplementedInClassReturnsCorrectValue(string className, decimal amount, int period, bool expected)
        {
            //arrange
            var classType = GetCustomType(className, $"Class '{className}'");

            var CanToProlong = classType.GetMethod("CanToProlong");
            AssertFailIfNull(CanToProlong, "Method 'CanToProlong'");

            var classInstance = Activator.CreateInstance(classType, amount, period);

            //act
            var actual = (bool)CanToProlong.Invoke(classInstance, null);

            //assert
            if (actual != expected)
                Assert.Fail($"Method 'CanToProlong' in class '{className}' works incorrectly.");
        }

        [TestCase("BaseDeposit", "BaseDeposit", 1000, 10, 10000, 0, -1)]
        [TestCase("BaseDeposit", "BaseDeposit", 1000, 2, 1000, 2, 0)]
        [TestCase("BaseDeposit", "BaseDeposit", 10000, 0, 1000, 10, 1)]
        [TestCase("BaseDeposit", "LongDeposit", 1000, 10, 1000, 10, -1)]
        [TestCase("BaseDeposit", "LongDeposit", 10000, 0, 1000, 0, 1)]
        [TestCase("BaseDeposit", "LongDeposit", 10000, 0, 1000, 10, 1)]
        [TestCase("BaseDeposit", "SpecialDeposit", 1000, 10, 10000, 0, -1)]
        [TestCase("BaseDeposit", "SpecialDeposit", 1000, 0, 10000, 0, -1)]
        [TestCase("BaseDeposit", "SpecialDeposit", 10000, 0, 1000, 10, 1)]
        [TestCase("LongDeposit", "BaseDeposit", 1000, 10, 10000, 0, -1)]
        [TestCase("LongDeposit", "BaseDeposit", 1000, 0, 1000, 0, 0)]
        [TestCase("LongDeposit", "BaseDeposit", 10000, 0, 1000, 10, 1)]
        [TestCase("LongDeposit", "LongDeposit", 1000, 10, 1000, 10, 0)]
        [TestCase("LongDeposit", "LongDeposit", 1000, 0, 10000, 0, -1)]
        [TestCase("LongDeposit", "LongDeposit", 10000, 0, 1000, 10, 1)]
        [TestCase("LongDeposit", "SpecialDeposit", 1000, 10, 10000, 0, -1)]
        [TestCase("LongDeposit", "SpecialDeposit", 10000, 0, 1000, 0, 1)]
        [TestCase("LongDeposit", "SpecialDeposit", 1000, 5, 1000, 10, -1)]
        [TestCase("SpecialDeposit", "BaseDeposit", 1000, 10, 10000, 0, -1)]
        [TestCase("SpecialDeposit", "BaseDeposit", 1000, 0, 1000, 0, 0)]
        [TestCase("SpecialDeposit", "BaseDeposit", 1000, 10, 1000, 10, 1)]
        [TestCase("SpecialDeposit", "LongDeposit", 1000, 10, 10000, 0, -1)]
        [TestCase("SpecialDeposit", "LongDeposit", 10000, 0, 1000, 10, 1)]
        [TestCase("SpecialDeposit", "LongDeposit", 1000, 10, 1000, 10, -1)]
        [TestCase("SpecialDeposit", "SpecialDeposit", 1000, 10, 10000, 0, -1)]
        [TestCase("SpecialDeposit", "SpecialDeposit", 1000, 10, 10000, 0, -1)]
        [TestCase("SpecialDeposit", "SpecialDeposit", 10000, 0, 1000, 10, 1)]
        public void DepositCompareToComparesByGeneralSum(string className1, string className2,
            decimal amount1, int period1, decimal amount2, int period2, int expected)
        {
            //arrange
            var classType1 = GetCustomType(className1, $"Class '{className1}'");
            var classType2 = GetCustomType(className2, $"Class '{className2}'");

            var genericType = GetCustomType("Deposit", "Class 'Deposit'");
            var genericInterfaceType = typeof(IComparable<>).MakeGenericType(genericType);

            if (!classType1.GetInterfaces().Contains(genericInterfaceType))
            {
                Assert.Fail($"Class '{className1}' doesn't implement interface 'IComparable<Deposit>'");
            }

            var CompareTo = classType1.GetMethod("CompareTo");

            var classInstance1 = Activator.CreateInstance(classType1, amount1, period1);
            var classInstance2 = Activator.CreateInstance(classType2, amount2, period2);

            //act
            var actual = (int)CompareTo.Invoke(classInstance1, new object[] { classInstance2 });

            //assert
            //If actual and expected are both less or both higher than zero, that counts
            if (actual * expected < 0 && actual != expected)
                Assert.Fail($"Method 'CompareTo' in class '{className1}' works incorrectly.");
        }

        [TestCase("SpecialDeposit")]
        [TestCase("LongDeposit")]
        [TestCase("BaseDeposit")]
        public void ClientGetEnumeratorReturnsDepositsInRightOrder(string depositChildName)
        {
            //arrange
            var clientType = GetCustomType("Client", $"Class 'Client'");

            var depositChildType = GetCustomType(depositChildName, $"Class '{depositChildName}'");

            var depositType = GetCustomType("Deposit", "Class 'Deposit'");

            var genericInterfaceType = typeof(IEnumerable<>).MakeGenericType(depositType);

            if (!clientType.GetInterfaces().Contains(genericInterfaceType))
            {
                Assert.Fail($"Class '{clientType}' doesn't implement interface 'IEnumerable<Deposit>'");
            }

            var depositsFieldInfo = clientType.GetField("deposits", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(depositsFieldInfo, "Field 'deposits'");

            var depositsArrayExpected = Array.CreateInstance(depositType, 10);



            for (int i = 0; i < depositsArrayExpected.Length; i++)
            {
                var deposit = Activator.CreateInstance(depositChildType, 1000m * i, i);
                depositsArrayExpected.SetValue(deposit, i);
            }

            var clientInstance = Activator.CreateInstance(clientType);

            Array.Copy(depositsArrayExpected, (Array)depositsFieldInfo.GetValue(clientInstance), depositsArrayExpected.Length);

            //act
            var depositsArrayActual = Array.CreateInstance(depositType, 10);

            IEnumerable enumerable = (IEnumerable)clientInstance;

            int index = 0;
            foreach (var deposit in enumerable)
            {
                depositsArrayActual.SetValue(deposit, index++);
            }

            //assert
            Assert.AreEqual(depositsArrayExpected, depositsArrayActual, "Method 'GetEnumerator' in class 'Client' works incorrectly.");
        }

        [TestCase("SpecialDeposit")]
        [TestCase("LongDeposit")]
        [TestCase("BaseDeposit")]
        public void ClientSortDepositsSortInDescendingOrder(string depositChildName)
        {
            //arrange
            var clientType = GetCustomType("Client", $"Class 'Client'");

            var depositChildType = GetCustomType(depositChildName, $"Class '{depositChildName}'");

            var depositType = GetCustomType("Deposit", "Class 'Deposit'");

            var depositsFieldInfo = clientType.GetField("deposits", BindingFlags.NonPublic | BindingFlags.Instance);
            AssertFailIfNull(depositsFieldInfo, "Field 'deposits'");

            var AddDeposit = clientType.GetMethod("AddDeposit");
            AssertFailIfNull(AddDeposit, "Method 'AddDeposit'");

            var SortDeposits = clientType.GetMethod("SortDeposits");
            AssertFailIfNull(SortDeposits, "Method 'SortDeposits'");

            var depositsArrayExpected = Array.CreateInstance(depositType, 10);

            for (int i = 0; i < depositsArrayExpected.Length - 1; i++)
            {
                var deposit = Activator.CreateInstance(depositChildType, 10000m, 15 - i);
                depositsArrayExpected.SetValue(deposit, i);
            }

            var clientInstance = Activator.CreateInstance(clientType);

            //fake mixing
            for (int i = 0; i < depositsArrayExpected.Length / 2; i++)
            {
                AddDeposit.Invoke(clientInstance, new object[] { depositsArrayExpected.GetValue(i) });
                AddDeposit.Invoke(clientInstance, new object[] { depositsArrayExpected.GetValue(9 - i) });
            }

            //act
            SortDeposits.Invoke(clientInstance, null);

            var depositsArrayActual = (Array)depositsFieldInfo.GetValue(clientInstance);

            //assert
            Assert.AreEqual(depositsArrayExpected, depositsArrayActual, "Method 'SortDeposits' in class 'Client' works incorrectly.");
        }

        static readonly object CountPossibleToProlongDeposit_TestCases = new object[]
        {
            new object[] { new decimal[] {500m, 1000m, 2000m}, new int[] {12, 24, 36},  4 },
            new object[] { new decimal[] {2000m, 4000m, 2000m}, new int[] {12, 24, 6},  6 },
            new object[] { new decimal[] {500m, 20m, 200m}, new int[] {60, 120, 37},  0 }
        };

        [TestCaseSource(nameof(CountPossibleToProlongDeposit_TestCases))]
        public void ClientCountPossibleToProlongDepositReturnsCorrectValue(decimal[] amountsForSpecialDeposits, int[] periodsForLongDeposits, int expected)
        {
            //arrange
            var clientType = GetCustomType("Client", $"Class 'Client'");

            var baseDepositType = GetCustomType("BaseDeposit", $"Class 'BaseDeposit'");
            var specialDepositType = GetCustomType("SpecialDeposit", $"Class 'SpecialDeposit'");
            var longDepositType = GetCustomType("LongDeposit", $"Class 'LongDeposit'");

            var AddDeposit = clientType.GetMethod("AddDeposit");
            AssertFailIfNull(AddDeposit, "Method 'AddDeposit'");

            var CountPossibleToProlongDeposit = clientType.GetMethod("CountPossibleToProlongDeposit");
            AssertFailIfNull(CountPossibleToProlongDeposit, "Method 'CountPossibleToProlongDeposit'");

            var client = Activator.CreateInstance(clientType);
            
            //Filling field with different deposits
            for (int i = 0; i < 3; i++)
            {
                AddDeposit.Invoke(client,
                    new object[] { Activator.CreateInstance(baseDepositType, 1000m, 1) });
            }
            for (int i = 0; i < amountsForSpecialDeposits.Length; i++)
            {
                AddDeposit.Invoke(client,
                    new object[] { Activator.CreateInstance(specialDepositType, amountsForSpecialDeposits[i], 1) });
            }
            for (int i = 0; i < periodsForLongDeposits.Length; i++)
            {
                AddDeposit.Invoke(client,
                    new object[] { Activator.CreateInstance(longDepositType, 1000m, periodsForLongDeposits[i]) });
            }

            //act
            var actual = (int) CountPossibleToProlongDeposit.Invoke(client, null);

            //assert
            if (actual != expected)
                Assert.Fail("Method 'CountPossibleToProlongDeposit' in class 'Client' works incorrectly.");
        }

        [TestCase("Deposit", "op_Equality")]
        [TestCase("Deposit", "op_Inequality")]
        [TestCase("Deposit", "op_LessThan")]
        [TestCase("Deposit", "op_GreaterThan")]
        public void ClassDepositContainsOperator(string className, string methodName)
        {
            var type = Type.GetType($"Interfaces.{className}" + ", Interfaces"); //typeof(Deposit);
            var method=type.GetMethod(methodName);
            Assert.That(method, Is.Not.Null);
        }
    }
}
