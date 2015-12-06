#include <iostream>
#include <conio.h>
#include <fstream>
#include <string>

using namespace std;

const int n = 1000;

int Check(string& line);
void Cut(string & line, int & x1, int & x2, int & y1, int & y2);
void TurnOn(int** &tab, int x1, int x2, int y1, int y2);
void TurnOff(int** &tab, int x1, int x2, int y1, int y2);
void Toggle(int** &tab, int x1, int x2, int y1, int y2);


int main()
{
	ifstream input("input.txt");
	string line;
	int ** lights = new int*[n];
	for (int i = 0; i < n; i++)
	{
		lights[i] = new int[n];
	}
	for (int i = 0; i < n; i++)
	{
		for (int j = 0; j < n; j++)
		{
			lights[i][j] = 0;

		}
	}
	int x1, x2, y1, y2;
	while (getline(input, line))
	{
		int what = Check(line);
		switch (what)
		{
		case 1:
		{
			Cut(line, x1, x2, y1, y2);
			TurnOn(lights, x1, x2, y1, y2);
			break;
		}
		case 2:
		{
			Cut(line, x1, x2, y1, y2);
			TurnOff(lights, x1, x2, y1, y2);
			break;
		}
		case 3:
		{
			Cut(line, x1, x2, y1, y2);
			Toggle(lights, x1, x2, y1, y2);
			break;
		}
		case -1:
		{
			system("cls");
			cout << "read error";
			_getch();
			return -1;
		}
		}
	}
	unsigned int counter = 0;
	for (int i = 0; i < n; i++)
	{
		for (int j = 0; j < n; j++)
		{
			counter += lights[i][j];
			
		}
		delete[] lights[i];
	}
	cout << "Counter: " << counter;
	delete[] lights;
	input.close();
	_getch();
	return 0;
}

int Check(string& line)
{
	if (line.find("turn on") != string::npos)
	{
		return 1;
	}
	if (line.find("turn off") != string::npos)
	{
		return 2;
	}
	if (line.find("toggle") != string::npos)
	{
		return 3;
	}
	return -1;
}

void Cut(string & line, int & x1, int & x2, int & y1, int & y2)
{
	int first_pos, last_pos, coma_pos;
	for (int i = 0; i < line.length(); i++)
	{
		if ((line[i] >= '0') && (line[i] <= '9'))
		{
			first_pos = i;
			break;
		}
	}
	for (int i = first_pos; i < line.length(); i++)
	{
		if (line[i] == ' ')
		{
			last_pos = i;
			break;
		}
	}
	string set1 = line.substr(first_pos, last_pos - first_pos);
	for (int i = 0; i < set1.length(); i++)
	{
		if (set1[i] == ',')
		{
			coma_pos = i;
			break;
		}
	}
	x1 = stoi(set1.substr(0, coma_pos));
	y1 = stoi(set1.substr(coma_pos + 1, set1.length() - 1));
	for (int i = last_pos; i < line.length(); i++)
	{
		if ((line[i] >= '0') && (line[i] <= '9'))
		{
			first_pos = i;
			break;
		}
	}
	for (int i = first_pos; i < line.length(); i++)
	{
		if (line[i] == ' ')
		{
			last_pos = i;
			break;
		}
	}
	string set2 = line.substr(first_pos, last_pos - first_pos);
	for (int i = 0; i < set2.length(); i++)
	{
		if (set2[i] == ',')
		{
			coma_pos = i;
			break;
		}
	}
	x2 = stoi(set2.substr(0, coma_pos));
	y2 = stoi(set2.substr(coma_pos + 1));
}

void TurnOn(int** &tab, int x1, int x2, int y1, int y2)
{
	for (int i = x1; i <= x2; i++)
	{
		for (int j = y1; j <= y2; j++)
		{
			++tab[i][j];
		}
	}
}

void TurnOff(int** &tab, int x1, int x2, int y1, int y2)
{
	for (int i = x1; i <= x2; i++)
	{
		for (int j = y1; j <= y2; j++)
		{
			if (tab[i][j] == 0 || tab[i][j] == 1)
			{
				tab[i][j] = 0;
			}
			else
			{
				--tab[i][j];
			}
			
		}
	}
}

void Toggle(int** &tab, int x1, int x2, int y1, int y2)
{
	for (int i = x1; i <= x2; i++)
	{
		for (int j = y1; j <= y2; j++)
		{
			tab[i][j] += 2;
		}
	}
}
