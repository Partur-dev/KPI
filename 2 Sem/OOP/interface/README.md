# Interfaces

Task Interfaces reffers to task Aggregation

## Task Aggregation
<details><summary>Aggregation description</summary>

To create classes **Deposit** (bank account), **BaseDeposit** (regular deposit), **SpecialDeposit** (special deposit), **LongDeposit** (long-term deposit), **Client** (bank client) with set functionality. 

1. To create abstract class **Deposit** and declare within it: 
 
- Public money property only for reading **Amount** (deposit amount) 
- Public integer property only for reading **Period** (time of deposit in months) 
- Constructor (for calling in class-inheritor) with parameters **depositAmount** and **depositPeriod**, which creates object deposit with specified sum for specified period.  
- Abstract method **Income**, which returns money value – amount of income from deposit. Income is the difference between sum, withdrawn from deposit upon expiration date and deposited sum.  
- Operators: ==, !=, <, >

2. To create classes that are inheritors of the class **Deposit**, which determine different options of deposit interest addition – class **BaseDeposit**, class **SpecialDeposit** and class **LongDeposit**. To implement in each class a constructor with parameters **amount** and **period**, which calls constructor of parent class.   

3. For each inheritor class – to implement own interest addition scheme and accordingly profit margin definitions, overriding abstract method **Income** in each class.   

**BaseDeposit** implies each month 5% of interest from current deposit sum. Each following month of income is calculated from the sum, which was received by adding to current income sum of the previous month and is rounded to hundredth.  

Example: 
Base amount – 1000,00

In a month – 105,00; income amount – 50,00 

In two months – 1102,50; income amount – 102,50

In three months – 1157,62; income amount – 157,62 

**SpecialDeposit** implies income addition each month, amount of which (in percent) equals to deposit expiration period. If during the first month 1% is added, during the second month – 2% from the sum obtained after first month and so on.   

Example: Base amount – 1000,00 

In a month – 1010,00; income amount – 10,00 

In two months – 1030,20; income amount – 30,20 

**LongDeposit** implies that during first 6 months, no percent is added to client’s deposit, but starting from 7th month, each month percent addition is 15% from current deposit sum, thus encouraging client to make long-term deposits.  

4. To create class **Client** (bank client) and declare within it: 


- Private field **deposits** (client deposits) – objects array of type Deposit 
- Constructor without parameters, which creates empty array deposits consisting of 10 elements 
- Method **AddDeposit** with parameter **deposit** for adding regular, special or long-term account into array on the first empty spot and returning true, or returning false, if accounts number limit is depleted (no empty space in array).  
- Method **TotalIncome**, returning total income amount based on all client’s deposits upon deposits expiration.  
- Method **MaxIncome**, returning maximum deposit income of all client’s deposits upon deposits expiration.  
- Method **GetIncomeByNumber** with integer parameter **number** (deposit number, which equals its index in array, increased by one), returning income from deposit with such number. If deposit with such number does not exist, method returns 0 value. 

</details>

## Task Interfaces

To add the following new functionalities to the project created in task Aggregation: 

1. To create interface **Iprolongable** (prolonging deposit) and declare within it method **CanToProlong** without parameters that returns logic value true or false, depending on the fact whether this specific deposit can be prolonged or not. 

2. To implement interface **IProlongable** in classes **SpecialDeposit** and **LongDeposit**. 

3. In addition, special deposit (**SpecialDeposit**) can be prolonged only when more than 1000 UAH were deposited, and long-term deposit (**LongDeposit**) can be prolonged if the period of deposit is no longer than 3 years. 

4. To implement standard generic interface **IComparable<Deposit>** in abstract class **Deposit**. Total sum amount (sum deposited plus interest during entire period) should be considered as comparison criteria of **Deposit** instances. 

5. To implement additionally in class **Client**: 

- interface **IEnumerable<Deposit>**. 
- Method **SortDeposits**, which performs deposits sorting in array **deposits** in descending order of total sum amount on deposit upon deposit expiration. 
- Method **CountPossibleToProlongDeposit**, which returns integer – amount of current client’s deposits that can be prolonged. 
