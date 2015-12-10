#include <iostream>
#include <fstream>
#include <conio.h>
#include <string>
#include <algorithm>

using namespace std;




void Cut(string input, string& location1, string& location2);
bool IsNotFound(string* locations, int locationsnmb, string input);
void Expand(string*& locations, int& size);
void AddLocations(string*& locations, int& locationsnmb, const string& file, int& size);
void AddDistances(string* pattern, int**& distances, int locationsnmb, const string& file);
int GetPosition(string* pattern, string location, int locationsnmb);
int CalculateDistance(string* pattern, string* locations, int** distances, int locationsnmb);


int main()
{
	int size = 5;
	string* locations = new string[size];
	int locationsnmb = 0;
	const string file = "input.txt";
	string lc1, lc2;
	AddLocations(locations, locationsnmb, file, size);
	sort(locations, locations + locationsnmb);
	int** distances = new int*[locationsnmb];
	for (int i = 0; i < locationsnmb; i++)
	{
		distances[i] = new int[locationsnmb] {0};
	}
	string* pattern = new string[locationsnmb];
	for (int i = 0; i < locationsnmb; i++)
	{
		pattern[i] = locations[i];
	}
	AddDistances(pattern, distances, locationsnmb, file);
	int result = INT32_MAX;
	int currentdistance = 0;
	do  {
			currentdistance = CalculateDistance(pattern, locations, distances, locationsnmb);
			if (currentdistance != -1)
			{
				if (currentdistance < result)
				{
					result = currentdistance;
				}
			}

		} while (next_permutation(locations, locations + locationsnmb));

	cout << result;
	_getch();
	for (int i = 0; i < locationsnmb; i++)
	{
		delete[] distances[i];
	}
	delete[] distances;
	delete[] pattern;
	delete[] locations;
	return 0;
}

void Cut(string input, string& location1, string& location2)
{
	int tmp = 0;
	for (tmp; tmp < input.length(); tmp++)
	{
		if (input[tmp] == ' ')
		{
			break;
		}
	}
	location1 = input.substr(0, tmp);
	location2 = "";
	tmp += 4;
	for (tmp; tmp < input.length(); tmp++)
	{
		if (input[tmp] == ' ')
		{
			break;
		}
		location2 += input[tmp];
	}
	return;
}

bool IsNotFound(string* locations, int locationsnmb, string input)
{
	for (int i = 0; i < locationsnmb; i++)
	{
		if (locations[i] == input)
		{
			return false;
		}
	}
	return true;
}

void AddLocations(string*& locations, int& locationsnmb, const string& file, int& size)
{
	string line;
	ifstream input(file);
	string lc1, lc2;
	while (getline(input, line))
	{
		if (locationsnmb == size)
		{
			Expand(locations, size);
		}
		Cut(line, lc1, lc2);
		if (IsNotFound(locations,locationsnmb,lc1))
		{
			locations[locationsnmb] = lc1;
			++locationsnmb;
		}
		if (IsNotFound(locations, locationsnmb, lc2))
		{
			locations[locationsnmb] = lc2;
			++locationsnmb;
		}
	}
	input.close();
	return;
}

void AddDistances(string* pattern, int**& distances, int locationsnmb, const string& file)
{
	int currentstart, currenttarget;
	for (int i = 0; i < locationsnmb; i++)
	{
		currentstart = i;
		for (int j = 0; j < locationsnmb; j++)
		{
			currenttarget = j;
			if (i == j)
			{
				continue;
			}
			string lookup, lookup2, line;
			lookup = pattern[i] + " to " + pattern[j];
			lookup2 = pattern[j] + " to " + pattern[i];
			ifstream input(file);
			while (getline(input, line))
			{
				if (line.find(lookup) != string::npos)
				{
					int tmp = 0;
					for (tmp; tmp < line.length(); tmp++)
					{
						if (line[tmp] == '=')
						{
							break;
						}
					}
					tmp += 2;
					line = line.substr(tmp);
					distances[i][j] = stoi(line);
				}
				if (line.find(lookup2) != string::npos)
				{
					int tmp = 0;
					for (tmp; tmp < line.length(); tmp++)
					{
						if (line[tmp] == '=')
						{
							break;
						}
					}
					tmp += 2;
					line = line.substr(tmp);
					distances[i][j] = stoi(line);
					break;
				}

			}
			input.close();
		}
	}
	return;
}

int GetPosition(string* pattern, string location, int locationsnmb)
{
	int i = 0;
	for (i; i < locationsnmb; i++)
	{
		if (pattern[i] == location)
		{
			break;
		}
	}
	return i;
}

int CalculateDistance(string* pattern, string* locations, int** distances, int locationsnmb)
{
	int distance = 0;
	int pos1, pos2;
	for (int i = 0; i < locationsnmb - 1; i++)
	{
		pos1 = GetPosition(pattern, locations[i], locationsnmb);
		pos2 = GetPosition(pattern, locations[i + 1], locationsnmb);
		if (distances[pos1][pos2] == 0)
		{
			return -1;
		}
		distance += distances[pos1][pos2];
	}
	return distance;
}

void Expand(string*& locations, int& size)
{
	string * temporary = new string[size];
	for (int i = 0; i < size; i++)
	{
		temporary[i] = locations[i];
	}
	delete[] locations;
	locations = new string[2 * size];
	for (int i = 0; i < size; i++)
	{
		locations[i] = temporary[i];
	}
	size *= 2;
	delete[] temporary;
}