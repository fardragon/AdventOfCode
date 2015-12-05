#include <iostream>
#include <conio.h>
#include <string>
#include <fstream>
#include <set>

using namespace std;

struct Letters
{
	char letter;
	int count;
};

bool VowelsNmb(string & linia);
bool Good(string & linia);
bool Alphabet(string & linia);
bool Doubles(string & linia);
bool Good2(string & linia);
bool Doubles2(string & linia);
bool Alphabet2(string & linia);






int main()
{
	ifstream plik("input.txt");
	string linia;
	int licznik = 0;
	while (getline(plik, linia))
	{
		if (Good2(linia))
		{
			++licznik;
		}
	}
	plik.close();
	cout << "Wynik: " << licznik;
	_getch();
	return 0;
}


bool Doubles(string & linia)
{
	for (int i = 0; i < linia.length() - 1; i++)
	{
		switch (linia[i])
		{
		case 'a':
		{
			if (linia[i + 1] == 'b')
			{
				return false;
			}
			break;
		}
		case 'c':
		{
			if (linia[i + 1] == 'd')
			{
				return false;
			}
			break;
		}
		case 'p':
		{
			if (linia[i + 1] == 'q')
			{
				return false;
			}
			break;
		}
		case 'x':
		{
			if (linia[i + 1] == 'y')
			{
				return false;
			}
			break;
		}



		}
	}
	return true;
}



bool VowelsNmb(string & linia)
{
	static char vowels[] = { 'a','e','i','o','u' };
	static set <char> svowels(vowels, vowels + 5);
	int vowelscount = 0;
	for (int i = 0; i < linia.length(); i++)
	{
		if (svowels.find(linia[i]) != svowels.end())
		{
			++vowelscount;
		}
	}
	if (vowelscount >= 3)
	{
		return true;
	}
	return false;

}

bool Alphabet(string & linia)
{
	for (int i = 0; i < linia.length() - 1; i++)
	{
		if (linia[i] == linia[i+1])
		{
			return true;
		}
	}
	return false;	
}


bool Good(string & linia)
{
	if ((VowelsNmb(linia))&&Alphabet(linia)&&Doubles(linia))
	{
		return true;
	}
	return false;
	

}

bool Doubles2(string & linia)
{
	for (int i = 0; i < linia.length()-1; i++)
	{
		if (linia.find(linia.substr(i,2),i+2)!=string::npos)
		{
			return true;
		}
		
	}
	return false;


}

bool Alphabet2(string & linia)
{
	for (int i = 0; i < linia.length() - 2; i++)
	{
		if (linia[i] == linia[i + 2])
		{
			return true;
		}
	}
	return false;
}

bool Good2(string & linia)
{
	if (Doubles2(linia) && Alphabet2(linia))
	{
		return true;
	}
	return false;
}