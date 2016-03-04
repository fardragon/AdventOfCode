#include <iostream>
#include <string>
#include <fstream>
#include <conio.h>


using namespace std;

string input;


int main()
{
	ifstream file("json.txt");
	char character;
	int sum = 0;
	string number;
	while (file >> character)
	{
		if ((character >= '0') && (character <= '9'))
		{
			number += character;
		}
		else if (number.length() > 0)
		{
				sum += stoi(number);
				number.clear();
		}
		
	}

	cout << sum;









	_getch();
	return 0;
}