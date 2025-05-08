using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using System.Reflection;

namespace Inheritance.Tests
{
    [TestFixture]
    public class InheritanceTestsAdvanced
    {
        [Test]
        public void CompanyClassExist()
        {
            GetClass("Company");
        }

        [Test]
        public void CompanyClassEmployeesFieldExist()
        {
            var classType = GetClass("Company");
            var employeeClass = GetClass("Employee");
            var field = classType.GetField("employees", BindingFlags.NonPublic | BindingFlags.Instance);
            Assert.Multiple(() =>
            {
                Assert.That(field, Is.Not.Null);
                Assert.That(field.FieldType, Is.EqualTo(employeeClass.MakeArrayType()));
            });
        }

        [Test]
        public void CompanyConstructorExist()
        {
            var classType = GetClass("Company");
            var employeeClass = GetClass("Employee");
            var constructor = classType.GetConstructor(new[] { employeeClass.MakeArrayType() });
            Assert.That(constructor, Is.Not.Null);
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

        [TestCaseSource("FunctionalData")]
        public void CompanyClassFunctionalityTest(object[] employees, string maxPayHolderBeforeBonus, string maxPayHolderAfterBonus, 
            decimal totalBeforeBonus, decimal totalAfterBonus)
        {
            var employeeType = GetClass("Employee");
            var companyType = GetClass("Company");
            var constructor = companyType.GetConstructor(new[] { employeeType.MakeArrayType() });
            Assert.Multiple(() =>
            {
                Assert.That(constructor, Is.Not.Null);
                var arr = Array.CreateInstance(employeeType, employees.Length);
                Array.Copy(employees, arr, employees.Length);
                var el = constructor.Invoke(new object[] { arr });
                var nameMaxSalaryMethod = companyType.GetMethod("NameMaxSalary");
                var giveEveryBodyBonusMethod = companyType.GetMethod("GiveEverybodyBonus");
                var totalToPayMethod = companyType.GetMethod("TotalToPay");
                Assert.That(nameMaxSalaryMethod, Is.Not.Null);
                Assert.That(giveEveryBodyBonusMethod, Is.Not.Null);
                Assert.That(totalToPayMethod, Is.Not.Null);

                Assert.That((string)nameMaxSalaryMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo(maxPayHolderBeforeBonus));
                Assert.That((decimal)totalToPayMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo(totalBeforeBonus));
                giveEveryBodyBonusMethod.Invoke(el, new object[] { (decimal)1 });
                Assert.That((decimal)totalToPayMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo(totalAfterBonus));
                Assert.That((string)nameMaxSalaryMethod.Invoke(el, Array.Empty<object>()),
                    Is.EqualTo(maxPayHolderAfterBonus));
            });
        }
#pragma warning disable S1144
#pragma warning disable S3878
#pragma warning disable IDE0051
        private static IEnumerable<TestCaseData> MethodsData
        {
            get
            {
                yield return new TestCaseData("Company", "GiveEverybodyBonus", typeof(void),
                    new[] { ("companyBonus", typeof(decimal)) });
                yield return new TestCaseData("Company", "TotalToPay", typeof(decimal),
                    Array.Empty<(string, Type)>());
                yield return new TestCaseData("Company", "NameMaxSalary", typeof(string),
                    Array.Empty<(string, Type)>());
            }
        }
#pragma warning restore
        private static Type GetClass(string className)
        {
            var classType = Type.GetType($"InheritanceTask.{className}, Inheritance");
            Assert.That(classType, Is.Not.Null, $"Class {className} do not exist");
            return classType;
        }

#pragma warning disable S1144
#pragma warning disable IDE0051
        private static IEnumerable<TestCaseData> FunctionalData
        {
            get
            {
                var employeeType = GetClass("Employee");
                var employeeConstructor = employeeType.GetConstructor(new[] { typeof(string), typeof(decimal) });
                var managerType = GetClass("Manager");
                var managerConstructor = managerType.GetConstructor(new[] { typeof(string), typeof(decimal), typeof(int) });
                var salesPersonType = GetClass("SalesPerson");
                var salesPersonConstructor = salesPersonType.GetConstructor(new[] { typeof(string), typeof(decimal), typeof(int) });
                if (employeeConstructor == null || managerConstructor == null || salesPersonConstructor == null)
                    Assert.Fail();
                yield return new TestCaseData((object)new[]
                {
                    employeeConstructor.Invoke(new object[] { "name1", (decimal)15 }),
                    employeeConstructor.Invoke(new object[] { "name2", (decimal)58 }),
                    employeeConstructor.Invoke(new object[] { "name3", (decimal)96 })
                }, "name3", "name3", (decimal)169, (decimal)172);
                yield return new TestCaseData((object)new[]
                {
                    managerConstructor.Invoke(new object[] { "name1", (decimal)1, 200 }),
                    managerConstructor.Invoke(new object[] { "name2", (decimal)45, 110 }),
                    managerConstructor.Invoke(new object[] { "name3", (decimal)69, 25 })
                }, "name3", "name1", (decimal)115, (decimal)1618);
                yield return new TestCaseData((object)new[]
                {
                    salesPersonConstructor.Invoke(new object[] { "name1", (decimal)13, 220 }),
                    salesPersonConstructor.Invoke(new object[] { "name2", (decimal)13, 110 }),
                    salesPersonConstructor.Invoke(new object[] { "name3", (decimal)14, 25 })
                }, "name3", "name1", (decimal)40, (decimal)46);
                yield return new TestCaseData((object) new[]
                {
                    employeeConstructor.Invoke(new object[] { "name1", (decimal)9 }),
                    employeeConstructor.Invoke(new object[] { "name2", (decimal)4 }),
                    employeeConstructor.Invoke(new object[] { "name3", (decimal)14 }),
                    managerConstructor.Invoke(new object[] { "name4", (decimal)14, 200 }),
                    managerConstructor.Invoke(new object[] { "name5", (decimal)14, 110 }),
                    managerConstructor.Invoke(new object[] { "name6", (decimal)14, 25 }),
                    salesPersonConstructor.Invoke(new object[] { "name7", (decimal)14, 220 }),
                    salesPersonConstructor.Invoke(new object[] { "name8", (decimal)14, 110 }),
                    salesPersonConstructor.Invoke(new object[] { "name9", (decimal)20, 25 })
                }, "name9", "name4", (decimal) 117, (decimal) 1629);
            }
        }
#pragma warning restore
    }
}

