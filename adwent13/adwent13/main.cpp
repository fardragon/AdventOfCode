#include <iostream>
#include <fstream>
#include <conio.h>
#include <string>
#include <algorithm>

using namespace std;

void AddPersons(string*& persons, int& personsnmb, const string& file, int& size);
void Expand(string*& persons, int& size);
void Cut(string input, string& person);
bool IsNotFound(string* persons, int personsnmb, string input);
void AddHappiness(string* pattern, int**& happiness, int personsnmb, const string& file);

int main()
{
	int personsnmb = 0;
	const string file = "input.txt";
	int size = 10;
	string* persons = new string[size];
	AddPersons(persons, personsnmb, file, size);
	sort(persons, persons + personsnmb);
	int** happiness = new int*[personsnmb];
	for (int i = 0; i < personsnmb; i++)
	{
		happiness[i] = new int[personsnmb] {0};
	}
	string* pattern = new string[personsnmb];
	for (int i = 0; i < personsnmb; i++)
	{
		pattern[i] = persons[i];
	}






	_getch();
	delete[] persons;
	return 0;
}

void Cut(string input, string& person)
{
	int i = 0;
	for (i; i < input.length(); i++)
	{
		if (input[i] == ' ')
		{
			break;
		}
	}
	person = input.substr(0, i);
	return;
}

void Expand(string*& persons, int& size)
{
	string * temporary = new string[size];
	for (int i = 0; i < size; i++)
	{
		temporary[i] = persons[i];
	}
	delete[] persons;
	persons = new string[2 * size];
	for (int i = 0; i < size; i++)
	{
		persons[i] = temporary[i];
	}
	size *= 2;
	delete[] temporary;
}

void AddPersons(string*& persons, int& personsnmb, const string& file, int& size)
{
	string line;
	ifstream input(file);
	string person;
	while (getline(input, line))
	{
		if (personsnmb == size)
		{
			Expand(persons, size);
		}
		Cut(line, person);
		if (IsNotFound(persons, personsnmb, person))
		{
			persons[personsnmb] = person;
			++personsnmb;
		}
	}
	input.close();
	return;
}

bool IsNotFound(string* persons, int personsnmb, string input)
{
	for (int i = 0; i < personsnmb; i++)
	{
		if (persons[i] == input)
		{
			return false;
		}
	}
	return true;
}

void AddHappiness(string* pattern, int**& happiness, int personsnmb, const string& file)
{
	int currentperson, targetperson;
	for (int i = 0; i < personsnmb; i++)
	{
		currentperson = i;
		for (int j = 0; j < personsnmb; j++)
		{
			targetperson = j;
			if (i == j)
			{
				continue;
			}
			ifstream input(file);

			
	
			
			input.close();
		}
	}
	return;
}