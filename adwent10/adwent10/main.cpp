#include <iostream>
#include <string>
#include <conio.h>

using namespace std;




int main()
{
	const int n = 50;
	string input = "1321131112";
	string output;
	int counter;
	char number;
	for (int i = 0; i < n; i++)
	{
		output = "";
		number = input[0];
		counter = 1;
		for (int j = 1; j <= input.length(); j++)
		{
			if (input[j] == number)
			{
				if (j == input.length())
				{
					++counter;
					output += to_string(counter);
					output += number;
					continue;
				}
				++counter;
				continue;
			}
			output += to_string(counter);
			output += number;
			number = input[j];
			counter = 1;
		}
		input = output;
	}

	cout << input << endl << output.length();
	_getch();
	return 0;
}