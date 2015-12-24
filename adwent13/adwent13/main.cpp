#include <iostream>
#include <fstream>
#include <conio.h>
#include <string>
#include <algorithm>


using namespace std;

void Parse(const string& file, string* order, int & orderpos);
bool IsFound(string* table, string who);
void CopyTable(string* input, string* output, int size); 
int** Matrix(int orderpos);
void DeleteMatrix(int** & happinessmatrix, int orderpos);
void EnterHappiness(int**& happinessmatrix, string* key, int orderpos, const string& file);
string GetSource(string line);
string GetTarget(string line);
int GetValue(string line);
int GetPos(string* key, string what);
int CalculateHappiness(int orderpos, int** happinessmatrix, string* order, string* key);

const int n = 8;



int main()
{
	const string file("input.txt");
	string order[n];
	string key[n];
	int orderpos = 0;
	Parse(file, order,orderpos);
	sort(order, order + orderpos);
	CopyTable(order, key, orderpos);
	int ** happinessmatrix = nullptr;
	happinessmatrix = Matrix(orderpos);
	EnterHappiness(happinessmatrix, key, orderpos, file);
	int happiness = 0;
	int currenthappiness;
	do
	{
		currenthappiness = CalculateHappiness(orderpos, happinessmatrix, order, key);
		if (currenthappiness > happiness)
		{
			happiness = currenthappiness;
		}
	} while (next_permutation(order, order + orderpos));

	cout << happiness;


	DeleteMatrix(happinessmatrix, orderpos);
	_getch();
	return 0;
}


bool IsFound(string* table, string who)
{
	for (int i = 0; i < n; i++)
	{
		if (table[i] == who)
		{
			return true;
		}
	}
	return false;
}

void Parse(const string& file, string* order, int & orderpos)
{
	ifstream input(file);
	string currentline;
	string person;
	int i = 0;
	while (getline(input, currentline))
	{
		for (i = 0; i < currentline.length(); i++)
		{
			if (currentline[i] == ' ')
			{
				break;
			}
		}
		person = currentline.substr(0, i);
		if (!IsFound(order, person))
		{
			order[orderpos] = person;
			++orderpos;
		}
	}
	input.close();
	return;
}

void CopyTable(string* input, string* output, int size)
{
	for (int i = 0; i < size; i++)
	{
		output[i] = input[i];
	}
	return;
}

int** Matrix(int orderpos)
{
	int** temp = nullptr;
	temp = new int*[orderpos];
	for (int i = 0; i < orderpos; i++)
	{
		temp[i] = new int[orderpos];
	}
	for (int i = 0; i < orderpos; i++)
	{
		for (int j = 0; j < orderpos; j++)
		{
			temp[i][j] = 0;
		}
	}
	return temp;
}

void DeleteMatrix(int** & happinessmatrix, int orderpos)
{
	for (int i = 0; i < orderpos; i++)
	{
		delete[] happinessmatrix[i];
	}
	delete[] happinessmatrix;
}

string GetSource(string line)
{
	int i = 0;
	for (i; i < line.length(); i++)
	{
		if (line[i] == ' ')
		{
			break;
		}
	}
	return line.substr(0, i);
}

string GetTarget(string line)
{
	int i = line.length() - 1;
	for (i; i >= 0; i--)
	{
		if (line[i] == ' ')
		{
			break;
		}
	}
	string temp = line.substr(i + 1);
	return temp.erase(temp.length() - 1);

}

int GetPos(string* key, string what)
{
	int i = 0;
	while (true)
	{
		if (key[i] == what)
		{
			return i;
		}
		++i;
	}
}

int GetValue(string line)
{
	if (line.find("gain") != string::npos)
	{
		int pos = line.find("gain");
		int start, end;
		for (pos; pos < line.length(); pos++)
		{
			if (line[pos] == ' ')
			{
				break;
			}
		}
		start = pos++;
		for (pos; pos < line.length(); pos++)
		{
			if (line[pos] == ' ')
			{
				break;
			}
		}
		end = pos;
		return stoi(line.substr(start, line.length() - end));
	}
	int pos = line.find("lose");
	int start, end;
	for (pos; pos < line.length(); pos++)
	{
		if (line[pos] == ' ')
		{
			break;
		}
	}
	start = pos++;
	for (pos; pos < line.length(); pos++)
	{
		if (line[pos] == ' ')
		{
			break;
		}
	}
	end = pos;
	return -stoi(line.substr(start, line.length() - end));
}

void EnterHappiness(int**& happinessmatrix, string* key, int orderpos, const string& file)
{
	ifstream input(file);
	int sourcepos, targetpos;
	string source, target, currentline;
	while (getline(input, currentline))
	{
		source = GetSource(currentline);
		target = GetTarget(currentline);
		sourcepos = GetPos(key, source);
		targetpos = GetPos(key, target);
		happinessmatrix[sourcepos][targetpos] = GetValue(currentline);
	}
	input.close();
	return;
}

int CalculateHappiness(int orderpos, int** happinessmatrix, string* order, string* key)
{
	int happiness=0;
	string source, target;
	int sourcepos, targetpos;
	source = order[0];
	sourcepos = GetPos(key, source);
	target = order[orderpos - 1];
	targetpos = GetPos(key, target);
	happiness += happinessmatrix[sourcepos] [targetpos];
	target = order[1];
	targetpos = GetPos(key, target);
	happiness += happinessmatrix[sourcepos][targetpos];
	for (int i = 1; i < orderpos - 1; i++)
	{
		source = order[i];
		sourcepos = GetPos(key, source);
		target = order[i - 1];
		targetpos = GetPos(key, target);
		happiness += happinessmatrix[sourcepos][targetpos];
		target = order[i+1];
		targetpos = GetPos(key, target);
		happiness += happinessmatrix[sourcepos][targetpos];

	}
	source = order[orderpos-1];
	sourcepos = GetPos(key, source);
	target = order[0];
	targetpos = GetPos(key, target);
	happiness += happinessmatrix[sourcepos][targetpos];
	target = order[orderpos-2];
	targetpos = GetPos(key, target);
	happiness += happinessmatrix[sourcepos][targetpos];

	return happiness;

}