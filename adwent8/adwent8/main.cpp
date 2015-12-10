#include <iostream>
#include <conio.h>
#include <fstream>
#include <string>

using namespace std;

//void clear(string& line);



int main()
{
	ifstream input("input.txt");
	int charcount = 0;
	int memorycount = 0;
	string line;

	while (getline(input, line))
	{
		string output = "\"";
		memorycount += line.length();
		for (int i = 0; i < line.length(); i++)
		{
			if ((line[i] == '\"') || (line[i] == '\\'))
			{
				output += '\\';
			}
			output += line[i];
		}
		output += "\"";
		cout << output << endl;
		charcount += output.length();
	}
	int diff = memorycount - charcount;
	cout << "Memory: " << memorycount << endl << "Real: " << charcount << endl << "Diff: " << diff;
	input.close();
	_getch();
	return 0;
}

/*
void clear(string& line)
{
	for (int i = 0; i < line.length(); i++)
	{
		if ((line[i] == '\\') && (line[i + 1] == '\\'))
		{
			line.insert(i, "\\\\");
			++i; ++i;
		}
		if ((line[i] == '\\') && (line[i + 1] == '\"'))
		{
			line.erase(i, 2);
			line.insert(i, "z");
		}
		if ((line[i] == '\\') && (line[i + 1] == 'x'))
		{
			line.erase(i, 4);
			line.insert(i, "z");
		}
	}
}*/