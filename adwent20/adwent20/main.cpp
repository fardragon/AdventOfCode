#include <iostream>
#include <fstream>

using namespace std;

struct house
{
	int number;
	int presents;
	house* next;
};

struct Houses
{
	house* first = nullptr;
};


void AddHouses(Houses& list, int how_many);
void AddPresents(Houses& list);
void ShowHouses(Houses list);
void DeleteHouses(Houses& list);
int Count(Houses list);

int main()
{
	Houses list;
	int i = 1;
	for (i; true; i++)
	{
		AddHouses(list, i);
		AddPresents(list);
		//ShowHouses(list);
		//cout << "Presents total: " << Count(list) << endl;
		if (Count(list) >= 36000000) break;
		DeleteHouses(list);

	}
	DeleteHouses(list);
	cout << i << endl;


















	return 0;
}



void AddHouses(Houses& list, int how_many)
{
	for (int i = how_many; i >= 1; i--)
	{
		list.first = new house{ i,0,list.first };
	}
	return;
}

void AddPresents(Houses& list)
{
	auto tmp = list.first;
	while (tmp)
	{
		for (int i = 1; i <= tmp->number; i++)
		{
			if (tmp->number % i == 0)
			{
				tmp->presents += 10 * i;
			}
		}
		tmp = tmp->next;
	}
}

void ShowHouses(Houses list)
{
	while (list.first)
	{
		cout << list.first->number << " : " << list.first->presents << endl;
		list.first = list.first->next;
	}

}

void DeleteHouses(Houses& list)
{
	while (list.first)
	{
		auto tmp = list.first;
		list.first = list.first->next;
		delete tmp;
	}

	list.first = nullptr;
	return;
}

int Count(Houses list)
{
	int counter = 0;
	while (list.first)
	{
		counter += list.first->presents;
		list.first = list.first->next;
	}
	return counter;

}