#include<iostream>
#include<fstream>
#include<conio.h>

using namespace std;


int main()
{
	int pietro = 0;
	int licznik = 0;
	ifstream plik("mikolaj.txt");
	char znak;
	while (plik >> znak)
	{	
		++licznik;
		if (znak == '(')
		{
			++pietro;
		}
		else
		{
			if (znak == ')')
			{
				--pietro;
			}
		}
		/*if (pietro == -1)
		{
			break;
		}*/
	}
	plik.close();
	cout << pietro << endl << licznik;
	_getch();
	return 0;
}
