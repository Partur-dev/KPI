using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using System.Reflection;

namespace Inheritance.Tests
{
    [TestFixture]
    public class InheritanceTestsLow
    {
        [TestCase("Employee")]
        [TestCase("Manager")]
        [TestCase("SalesPerson")]
        public void ClassExist(string className)
        {
            GetClass(className);
        }

        [TestCase("Employee", "name", typeof(string))]
        [TestCase("Employee", "salary", typeof(decimal))]
        [TestCase("Employee", "bonus", typeof(decimal))]
        [TestCase("Manager", "quantity", typeof(int))]
        [TestCase("SalesPerson", "percent", typeof(int))]
        public void FieldExist(string className, string fieldName, Type fieldType)
        {
            var classType = GetClass(className);
            var field = classType.GetField(fieldName, BindingFlags.NonPublic | BindingFlags.Instance);
            Assert.Multiple(() =>
            {
                Assert.That(field, Is.Not.Null);
                Assert.That(field.FieldType, Is.EqualTo(fieldType));
            });
        }

        [TestCase("Employee", "Name", typeof(string), false)]
        [TestCase("Employee", "Salary", typeof(decimal), true)]
        public void PropertyExist(string className, string propertyName, Type propertyType, bool isWriteable,
            bool isReadable = true)
        {
            var classType = GetClass(className);
            var property = classType.GetProperty(propertyName);
            Assert.Multiple(() =>
            {
                Assert.That(property, Is.Not.Null);
                Assert.That(property.PropertyType, Is.EqualTo(propertyType));
                Assert.That(property.CanRead, Is.EqualTo(isReadable));
                Assert.That(property.CanWrite, Is.EqualTo(isWriteable));
            });
        }

        [TestCaseSource("ConstructorData")]
        public void ConstructorExist(string className, (string, Type)[] constructorTypes)
        {
            var classType = GetClass(className);
            var constructor = classType.GetConstructor(constructorTypes.Select(x => x.Item2).ToArray());
            Assert.Multiple(() =>
            {
                Assert.That(constructor, Is.Not.Null);
                Assert.That(constructor.GetParameters()
                    .Select(x => (x.Name, x.ParameterType)).SequenceEqual(constructorTypes),
                    Is.True);
            });
        }

        [TestCaseSource("MethodsData")]
        public void MethodExist(string className, string methodName, Type returnType, (string, Type)[] parameters)
        {
            var classType = GetClass(className);
            var method = classType.GetMethod(methodName);
            Assert.Multiple(() =>
            {
                Assert.That(method, Is.Not.Null);
                Assert.That(method.ReturnType, Is.EqualTo(returnType));
                Assert.That(method.GetParameters()
                        .Select(x => (x.Name, x.ParameterType)).SequenceEqual(parameters),
                    Is.True);
            });
        }

        [TestCase("Manager")]
        [TestCase("SalesPerson")]
        public void InheritanceCheck(string className)
        {
            var employeeType = GetClass("Employee");
            var classType = GetClass(className);
            Assert.That(classType.BaseType, Is.EqualTo(employeeType));
        }

        [TestCase("Manager", "SetBonus")]
        [TestCase("SalesPerson", "SetBonus")]
        public void VirtualMethodCheck(string className, string methodName)
        {
            var employeeType = GetClass("Employee");
            var classType = GetClass(className);
            Assert.Multiple(() =>
            {
                Assert.That(classType.BaseType, Is.EqualTo(employeeType));
                Assert.That(employeeType.GetMethod(methodName), Is.Not.Null);
                Assert.That(classType.GetMethod(methodName), Is.Not.Null);
                Assert.That(employeeType.GetMethod(methodName).IsVirtual, Is.True);
                Assert.That(classType.GetMethod(methodName).DeclaringType, Is.Not.EqualTo(employeeType));
            });
        }

        [Test]
        public void EmployeeFunctionalTest()
        {
            var classType = GetClass("Employee");
            var constructor = classType.GetConstructor(new[] { typeof(string), typeof(decimal) });
            Assert.Multiple(() =>
            {
                Assert.That(constructor, Is.Not.Null);
                var el = constructor.Invoke(new object[] { "name", (decimal)14 });
                var setBonus = classType.GetMethod("SetBonus");
                Assert.That(setBonus, Is.Not.Null);
                setBonus.Invoke(el, new object[] { (decimal)5 });
                var toPay = classType.GetMethod("ToPay");
                Assert.That(toPay, Is.Not.Null);
                var res = toPay.Invoke(el, Array.Empty<object>());
                Assert.That(res, Is.InstanceOf<decimal>());
                Assert.That((decimal)res, Is.EqualTo((decimal)19));
                var salary = classType.GetProperty("Salary");
                Assert.That(salary, Is.Not.Null);
                salary.SetMethod.Invoke(el, new object[] { (decimal)45 });
                Assert.That((decimal)salary.GetMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo((decimal)45));
                res = toPay.Invoke(el, Array.Empty<object>());
                Assert.That((decimal)res, Is.EqualTo((decimal)50));
                var nameProperty = classType.GetProperty("Name");
                Assert.That(nameProperty, Is.Not.Null);
                Assert.That((string)nameProperty.GetMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo("name"));
            });
        }

        [TestCase(200, 1000)]
        [TestCase(110, 500)]
        [TestCase(25, 0)]
        public void ManagerFunctionalTest(int quantity, decimal bonus)
        {
            var classType = GetClass("Manager");
            var constructor = classType.GetConstructor(new[] { typeof(string), typeof(decimal), typeof(int) });
            Assert.Multiple(() =>
            {
                Assert.That(constructor, Is.Not.Null);
                var el = constructor.Invoke(new object[] { "name", (decimal)14, quantity });
                var setBonus = classType.GetMethod("SetBonus");
                Assert.That(setBonus, Is.Not.Null);
                setBonus.Invoke(el, new object[] { (decimal)0 });
                var toPay = classType.GetMethod("ToPay");
                Assert.That(toPay, Is.Not.Null);
                var res = toPay.Invoke(el, Array.Empty<object>());
                Assert.That(res, Is.InstanceOf<decimal>());
                Assert.That((decimal)res, Is.EqualTo((decimal)14 + bonus));
                var salary = classType.GetProperty("Salary");
                Assert.That(salary, Is.Not.Null);
                salary.SetMethod.Invoke(el, new object[] { (decimal)45 });
                Assert.That((decimal)salary.GetMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo((decimal)45));
                res = toPay.Invoke(el, Array.Empty<object>());
                Assert.That((decimal)res, Is.EqualTo((decimal)45 + bonus));
                var nameProperty = classType.GetProperty("Name");
                Assert.That(nameProperty, Is.Not.Null);
                Assert.That((string)nameProperty.GetMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo("name"));
            });
        }

        [TestCase(220, 30)]
        [TestCase(110, 20)]
        [TestCase(25, 10)]
        public void SalesPersonFunctionalTest(int percent, decimal bonus)
        {
            var classType = GetClass("SalesPerson");
            var constructor = classType.GetConstructor(new[] { typeof(string), typeof(decimal), typeof(int) });
            Assert.Multiple(() =>
            {
                Assert.That(constructor, Is.Not.Null);
                var el = constructor.Invoke(new object[] { "name", (decimal)14, percent });
                var setBonus = classType.GetMethod("SetBonus");
                Assert.That(setBonus, Is.Not.Null);
                setBonus.Invoke(el, new object[] { (decimal)10 });
                var toPay = classType.GetMethod("ToPay");
                Assert.That(toPay, Is.Not.Null);
                var res = toPay.Invoke(el, Array.Empty<object>());
                Assert.That(res, Is.InstanceOf<decimal>());
                Assert.That((decimal)res, Is.EqualTo((decimal)14 + bonus));
                var salary = classType.GetProperty("Salary");
                Assert.That(salary, Is.Not.Null);
                salary.SetMethod.Invoke(el, new object[] { (decimal)45 });
                Assert.That((decimal)salary.GetMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo((decimal)45));
                res = toPay.Invoke(el, Array.Empty<object>());
                Assert.That((decimal)res, Is.EqualTo((decimal)45 + bonus));
                var nameProperty = classType.GetProperty("Name");
                Assert.That(nameProperty, Is.Not.Null);
                Assert.That((string)nameProperty.GetMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo("name"));
            });
        }
#pragma warning disable S1144
#pragma warning disable S3878
#pragma warning disable IDE0051
        private static IEnumerable<TestCaseData> MethodsData
        {
            get
            {
                yield return new TestCaseData("Employee", "SetBonus", typeof(void),
                    new[] { ("bonus", typeof(decimal)) });
                yield return new TestCaseData("SalesPerson", "SetBonus", typeof(void),
                    new[] { ("bonus", typeof(decimal)) });
                yield return new TestCaseData("Manager", "SetBonus", typeof(void),
                    new[] { ("bonus", typeof(decimal)) });
                yield return new TestCaseData("Employee", "ToPay", typeof(decimal),
                    new List<(string, Type)>().ToArray());
                yield return new TestCaseData("SalesPerson", "ToPay", typeof(decimal),
                    new List<(string, Type)>().ToArray());
                yield return new TestCaseData("Manager", "ToPay", typeof(decimal),
                    new List<(string, Type)>().ToArray());
            }
        }


        private static IEnumerable<TestCaseData> ConstructorData
        {
            get
            {
                yield return new TestCaseData("Employee",
                    new[] { ("name", typeof(string)), ("salary", typeof(decimal)) });
                yield return new TestCaseData("Manager",
                    new[] { ("name", typeof(string)), ("salary", typeof(decimal)), ("clientAmount", typeof(int)) });
                yield return new TestCaseData("SalesPerson",
                    new[] { ("name", typeof(string)), ("salary", typeof(decimal)), ("percent", typeof(int)) });
            }
        }
#pragma warning restore
        private static Type GetClass(string className)
        {
            var classType = Type.GetType($"InheritanceTask.{className}, Inheritance");
            Assert.That(classType, Is.Not.Null);
            return classType;
        }

    }

}

