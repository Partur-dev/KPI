using System;
using System.Linq;

namespace Class
{
    public class Rectangle
    {
        private double sideA;
        private double sideB;

        public Rectangle(double a, double b)
        {
            sideA = a;
            sideB = b;
        }

        public Rectangle(double a)
        {
            sideA = a;
            sideB = 5;
        }

        public Rectangle()
        {
            sideA = 4;
            sideB = 3;
        }

        public double GetSideA()
        {
            return sideA;
        }

        public double GetSideB()
        {
            return sideB;
        }

        public double Area()
        {
            return sideA * sideB;
        }

        public double Perimeter()
        {
            return 2 * (sideA + sideB);
        }

        public bool IsSquare()
        {
            return sideA == sideB;
        }

        public void ReplaceSides()
        {
            double temp = sideA;
            sideA = sideB;
            sideB = temp;
        }
    }

    public class ArrayRectangles
    {
        private readonly Rectangle[] rectangle_array;

        public ArrayRectangles(int n)
        {
            rectangle_array = new Rectangle[n];
        }

        public ArrayRectangles(Rectangle[] rectangles)
        {
            rectangle_array = rectangles;
        }

        public bool AddRectangle(Rectangle rectangle)
        {
            var index = Array.IndexOf(rectangle_array, null);
            if (index == -1)
            {
                return false;
            }

            rectangle_array[index] = rectangle;
            return true;
        }

        public int NumberMaxArea()
        {
            return rectangle_array
                .Select((r, i) => new { Rectangle = r, Index = i })
                .OrderByDescending(x => x.Rectangle.Area())
                .First()
                .Index;
        }

        public int NumberMinPerimeter()
        {
            return rectangle_array
                .Select((r, i) => new { Rectangle = r, Index = i })
                .OrderBy(x => x.Rectangle.Perimeter())
                .First().Index;
        }

        public int NumberSquare()
        {
            return rectangle_array.Count(r => r.IsSquare());
        }
    }
}
