#include <iostream>
#include <fstream>
#include <conio.h>
#include <string>



using namespace std;

void ClearTable(bool**& lights,int size);
void Parse(const string& file, bool**& lights, int size);
int Count(bool** lights, int size);
void Sunset(bool**& today, bool** tomorrow, int size);
int CountNeighboors(bool** today, int size, int x, int y);
void Show(bool** lights, int size);
void Prepare(bool** today, bool**& tomorrow, int size);
void SecondPart(bool**& tomorrow, int size);




int main()
{
	const int n = 100;
	const int steps = 100;
	const string file = "input.txt";
	bool** lightstoday = new bool*[n];
	bool** lightstomorrow = new bool*[n];
	for (int i = 0; i < n; i++)
	{
		lightstoday[i] = new bool[n];
		lightstomorrow[i] = new bool[n];
	}
	ClearTable(lightstoday, n);
	ClearTable(lightstomorrow, n);
	Parse(file, lightstoday,n);
	SecondPart(lightstoday, n);
	for (int i = 0; i < steps; i++)
	{
		Prepare(lightstoday, lightstomorrow, n);
		Sunset(lightstoday, lightstomorrow, n);
	}
	cout << Count(lightstoday, n);



	for (int i = 0; i < n; i++)
	{
		delete[] lightstoday[i];
		delete[] lightstomorrow[i];
	}
	delete[] lightstoday;
	delete[] lightstomorrow;
	_getch();
	return 0;
}

void ClearTable(bool**& lights,int size)
{
	for (int i = 0; i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			lights[i][j] = false;
		}
	}
	return;
}

int Count(bool** lights,int size)
{
	int counter = 0;
	for (int i = 0; i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			if (lights[i][j])
			{
				++counter;
			}
		}
	}
	return counter;
}

void Parse(const string& file, bool**& lights,int size)
{
	char curr;
	ifstream input(file);
	int x = 0, y = 0;
	while (input >> curr)
	{
		if (x == size)
		{
			++y;
			x = 0;
		}
		if (curr == '#')
		{
			lights[y][x++] = true;
		}
		else
		{
			++x;
		}
	}
	return;
}

void Sunset(bool**& today, bool** tomorrow,int size)
{
	for (int i = 0; i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			today[i][j] = tomorrow[i][j];
		}
	}

}

int CountNeighboors(bool** today, int size, int x, int y)
{
	int counter = 0;
	for (int i = x - 1; i <= x + 1; i++)
	{
		if ((i < 0) || (i>size-1))
		{
			continue;
		}
		for (int j = y - 1; j <= y + 1; j++)
		{
			if ((j < 0) || (j>size-1))
			{
				continue;
			}
			if (today[i][j])
			{
				++counter;
			}
		}
	}
	if (today[x][y])
	{
		--counter;
	}
	return counter;

}
void Show(bool** lights, int size)
{
	for (int i = 0; i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			cout << lights[i][j] << " ";
		}
		cout << endl;
	}
	cout << endl << endl;
}

void Prepare(bool** today, bool**& tomorrow, int size)
{
	int neighboors;
	for (int i = 0; i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			neighboors = CountNeighboors(today, size, i, j);
			if (today[i][j])
			{
				if ((neighboors == 2) || (neighboors == 3))
				{
					tomorrow[i][j] = true;
				}
				else
				{
					tomorrow[i][j] = false;
				}
			}
			else
			{
				if (neighboors == 3)
				{
					tomorrow[i][j] = true;
				}
				else
				{
					tomorrow[i][j] = false;
				}
			}
		}
	}
	SecondPart(tomorrow, size);
}

void SecondPart(bool**& tomorrow, int size)
{
	tomorrow[0][0] = true;
	tomorrow[0][size - 1] = true;
	tomorrow[size - 1][0] = true;
	tomorrow[size - 1][size - 1] = true;
}

