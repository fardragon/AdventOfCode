#include <iostream>
#include <string>
#include <conio.h>
#include "md5.h"


using namespace std;

bool Check(string input)
{
	for (int i = 0; i < 6; i++)
	{
		if (input[i] != '0')
		{
			return false;
		}
	}
	return true;
}

int main(int argc, char *argv[])
{
	MD5 md5;
	string input = "iwrupvqb";
	string output;
	bool koniec = false;
	int wynik = 0;
	while (!koniec)
	{
		++wynik;
		output = (input + to_string(wynik));
		output = md5(output);
		koniec = Check(output);
		//cout << output << "                                    " << wynik << endl;
	}

	cout << wynik;
	_getch();
	return 0;
}