#include <iostream>
#include <conio.h>
#include <fstream>

using namespace std;


int main()
{
	const int n = 1000;
	int ** sciezka = new int*[n];
	for (int i = 0; i < n; i++)
	{
		sciezka[i] = new int[n];
	}
	int x = n / 2;
	int y = n / 2;
	int xr = x;
	int yr = y;
	char ruch;
	sciezka[x][y] = 1;
	ifstream plik("test.txt");
	bool kto = true;
	while (plik >> ruch)
	{	
		switch (ruch)
		{
		case '<':
		{
			if (kto)
			{
				--x;
			}
			else
			{
				--xr;
			}
			
			break;
		}
		case '>':
		{
			if (kto)
			{
				++x;
			}
			else
			{
				++xr;
			}
			break;
		}
		case '^':
		{
			if (kto)
			{
				++y;
			}
			else
			{
				++yr;
			}
			break;
		}
		case 'v':
		{
			if (kto)
			{
				--y;
			}
			else
			{
				--yr;
			}
			break;
		}
		}
		if (kto)
		{
			sciezka[x][y] = 1;
		}
		else
		{
			sciezka[xr][yr] = 1;
		}
		kto = !kto;
	}
	int licznik = 0;
	for (int i = 0; i < n; i++)
	{
		for (int j = 0; j < n; j++)
		{
			if (sciezka[i][j] == 1)
			{
				++licznik;
			}
		}
	}
	for (int i = 0; i < n; i++)
	{
		delete[] sciezka[i];
	}
	delete[] sciezka;

	cout << licznik;
	plik.close();
	_getch();
	return 0;
}

