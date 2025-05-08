# Functions

## Task 1 
Create function _**IsSorted**_, determining whether a given _**array**_ of integer values of arbitrary length is sorted in a given _**order**_ (the order is set up by enum value _**SortOrder**_). Array and sort order are passed by parameters. Function does not change the array
 
## Task 2
Create function _**Transform**_, replacing the value of each element of an integer **_array_** with the sum of this element value and its index, only if the given **_array_** is sorted in the given **_order_** (the order is set up by enum value **_SortOrder_**). Array and sort order are passed by parameters. To check, if the array is sorted, the function **_IsSorted_** from the Task 1 is called.  

Example 

```
For {5, 17, 24, 88, 33, 2} and “ascending” sort order values in the array do not change; 
For {15, 10, 3} and “ascending” sort order values in the array do not change; 
For {15, 10, 3} and “descending” sort order the values in the array change to {15, 11, 5} 
```
## Task 3
Create function **_MultArithmeticElements_**, which determines the multiplication of a given number of first **_n_** elements of arithmetic progression of real numbers with a given initial element of progression **_a(1)_** and progression step **_t_**. a(n) is calculated by the formula a(n+1) = a(n) + t.  

Example 

```
For a(1) = 5, t = 3, n = 4  multiplication equals to 5*8*11*14 = 6160 
```
## Task 4
Create function **_SumGeometricElements_**, determining the sum of the first elements of a decreasing geometric progression of real numbers with a given initial element of a progression **_a(1)_**) and a given progression step **_t_**, while the last element must be greater than a given **_alim_**. an is calculated by the formula a(n+1) = a(n) * t, 0<t<1.  

Example 

```
For a progression, where a(1) = 100, and t = 0.5, the sum of the first elements, grater than alim = 20, equals to 100+50+25 = 175  
```
