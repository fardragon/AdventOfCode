#include <iostream>
#include <string>
#include <conio.h>

using namespace std;


bool Inc(string& input, int pos);
bool ThreeLetters(string& input);
bool RestrictedLetters(string& input);
bool Doubles(string& input);


int main()
{
	string input = "hepxxyzz";
	bool found = false;
	int counter = 0;
	while (Inc(input, input.length() - 1))
	{
		++counter;
		if (ThreeLetters(input) && RestrictedLetters(input) && Doubles(input))
		{
			found = true;
			break;
		}
	} 
	
	if (found)
	{
		cout << "Password: " << input << endl << "after: " << counter << " increment(s)";
	}
	else
	{
		cout << "Not found " << "after: " << counter << " increment(s)";
	}


	_getch();
	return 0;
}


bool Inc(string& input, int pos)
{
	if (input[pos] != 'z')
	{
		input[pos] += 1;
		return true;
	}
	if ((pos == 0) && (input[pos] == 'z'))
	{
		return false;
	}
	if (Inc(input, pos - 1))
	{
		input[pos] = 'a';
		return true;
	}
	return false;
}

bool ThreeLetters(string& input)
{
	for (int i = 0; i < input.length()-2; i++)
	{
		if (input[i] > 'x')
		{
			continue;
		}
		if (input[i+1] > 'y')
		{
			continue;
		}
		if (input[i + 2] == 'z')
		{
			if ((input[i] == 'x') && (input[i + 1] == 'y'))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		if (((input[i]+1) == input[i+1]) && (input[i + 1] == (input[i+2] - 1)))
		{
			return true;
		}
	}
	return false;
}

bool RestrictedLetters(string& input)
{
	for (int i = 0; i < input.length(); i++)
	{
		if ((input[i] == 'i') || (input[i] == 'o') || (input[i] == 'l'))
		{
			return false;
		}
	}
	return true;
}

bool Doubles(string& input)
{
	int count = 0;
	for (int i = 0; i < input.length()-1; i++)
	{
		if (input[i] == input[i + 1])
		{
			++count;
			++i;
		}
	}
	if (count >= 2) return true;
	return false;
}