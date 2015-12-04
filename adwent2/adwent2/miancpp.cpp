#include <iostream>
#include <fstream>
#include <string>
#include <conio.h>
#include <algorithm>

using namespace std;

int Area(int a, int b, int c)
{
	int p1, p2, p3;
	p1 = a * b;
	p2 = a * c;
	p3 = b * c; 
	return (2 * p1) + (2 * p2) + (2 * p3) + min(p1, min (p2,p3));

}

int Ribbonn(int a, int b, int c)
{
	int tab[3] = { a,b,c };
	sort(tab,tab+3);
	return 2 * tab[0] + 2 * tab[1] + a*b*c;
}


int main()
{
	ifstream plik ("test.txt");
	string linia;
	int a, b, c;
	int n = 0;
	unsigned int pole = 0;
	unsigned int ribbon = 0;
	while (getline(plik, linia))
	{
		int iksy[2] = { NAN,NAN };
		for (int i = 0; i < linia.length(); i++)
		{
			
			if (linia[i] == 'x')
			{
				iksy[n++] = i;
			}
		}

		a = stoi(linia.substr(0, iksy[0]));
		b = stoi(linia.substr(iksy[0] + 1, linia.length() - iksy[1]));
		c = stoi(linia.substr(iksy[1] + 1, linia.npos));
		n = 0;
		pole += Area(a, b, c);
		ribbon += Ribbonn(a, b, c);
	}





	plik.close();
	cout << pole << endl << ribbon;
	_getch();
	return 0;
}