#include <iostream>
#include <fstream>
#include <string>
#include <conio.h>

using namespace std;

struct Aunt
{
	int attributes[11];
	Aunt* next;
};

struct Aunts
{
	Aunt* head = nullptr;
};

enum class attrib {number, children, cats, samoyeds, pomeranians, akitas, vizslas, goldfish, trees, cars, perfumes};
void Add(Aunts& list, int* attribs);
void NeutralizeTable(int* & attribs);
void ParseFile(Aunts& list, const string filename, string* key);
void Show(Aunts list, string* key);
void Delete(Aunts & list);
void Sweep(Aunts& list, int attrib, int value);
void SweepGreater(Aunts& list, int attrib, int value);
void SweepLesser(Aunts& list, int attrib, int value);








int main()
{
	const string file = "input.txt";
	Aunts list;
	string key[10] = {"children", "cats", "samoyeds", "pomeranians", "akitas", "vizslas","goldfish", "trees", "cars", "perfumes" };
	ParseFile(list, file, key);
	Sweep(list, 1, 3);
	/*Sweep(list, 2, 7);*/ SweepGreater(list, 2, 7);
	Sweep(list, 3, 2);
	/*Sweep(list, 4, 3);*/ SweepLesser(list, 4, 3);
	Sweep(list, 5, 0);
	Sweep(list, 6, 0);
	/*Sweep(list, 7, 5);*/ SweepLesser(list, 7, 5);
	/*Sweep(list, 8, 3);*/ SweepGreater(list, 8, 3);
	Sweep(list, 9, 2);
	Sweep(list, 10, 1);
	Show(list,key);
	Delete(list);
	_getch();
	return 0;
}

void Add(Aunts& list, int* attribs) {
	list.head = new Aunt
	{
		{attribs[0],attribs[1],attribs[2] ,attribs[3] ,attribs[4] ,attribs[5] ,attribs[6] ,attribs[7] ,attribs[8] ,attribs[9] ,attribs[10] },
		list.head
	};

}

void NeutralizeTable(int* & attribs)
{
	for (int i = 0; i < 11; i++)
	{
		attribs[i] = -1;
	}
	return;
}

void ParseFile(Aunts& list, const string filename, string* key)
{
	int* attribs = new int [11];
	ifstream input (filename);
	string currentline;
	int pos1, pos2,count;
	while (getline(input, currentline))
	{
		NeutralizeTable(attribs);
		pos1 = 4;
		count = 0;
		for (pos1; pos1 < currentline.length(); pos1++)
		{
			if (currentline[pos1] == ':')
			{
				break;
			}
			++count;
		}
		attribs[0] = stoi(currentline.substr(4, count));
		for (int i = 0; i < 10; i++)
		{
			if (currentline.find(key[i]) != string::npos)
			{
				pos1 = currentline.find(key[i]) + 1;
				for (pos1; pos1 < currentline.length(); pos1++)
				{
					if (currentline[pos1] == ' ')
					{
						break;
					}
				}
				pos2 = ++pos1;
				count = 0;
				for (pos2; pos2 < currentline.length(); pos2++)
				{
					if ((currentline[pos2] >= '0') && (currentline[pos2] <= '9'))
					{
						++count;
					}
					else
					{
						break;
					}
				}
				attribs[i + 1] = stoi(currentline.substr(pos1,count));
			}
			
		}
		Add(list, attribs);



	}
	input.close();
	delete[] attribs;
	return;
}

void Show(Aunts list, string* key)
{
	while (list.head)
	{
		for (int i = 0; i < 11; i++)
		{
			if (list.head->attributes[i] == -1) continue;
			 if (i != 0) cout << key[i-1] << ": ";
			cout << list.head->attributes[i] << " ";
		}
		cout << endl;
		list.head = list.head->next;
	}
}

void Delete(Aunts & list)
{
	auto tmp = list.head;
	while (list.head)
	{
		tmp = list.head;
		list.head = list.head->next;
		delete tmp;
	}
	list.head = nullptr;
}

void Sweep(Aunts& list, int attrib, int value)
{

	auto before = list.head;
	auto tmp = list.head;
	while (tmp)
	{
		if ((tmp->attributes[attrib] != value) && (tmp->attributes[attrib] != -1))
		{
			if (tmp == list.head)
			{
				list.head = list.head->next;
				delete tmp;
				tmp = list.head;
			}
			else
			{
				before->next = tmp->next;
				auto del = tmp->next;
				delete tmp;
				tmp = del;
			}
		}
		else
		{
			before = tmp;
			tmp = tmp->next;
		}
	}
}   

void SweepGreater(Aunts& list, int attrib, int value)
{

	auto before = list.head;
	auto tmp = list.head;
	while (tmp)
	{
		if ((tmp->attributes[attrib] < value) && (tmp->attributes[attrib] != -1))
		{
			if (tmp == list.head)
			{
				list.head = list.head->next;
				delete tmp;
				tmp = list.head;
			}
			else
			{
				before->next = tmp->next;
				auto del = tmp->next;
				delete tmp;
				tmp = del;
			}
		}
		else
		{
			before = tmp;
			tmp = tmp->next;
		}
	}
}

void SweepLesser(Aunts& list, int attrib, int value)
{

	auto before = list.head;
	auto tmp = list.head;
	while (tmp)
	{
		if ((tmp->attributes[attrib] > value) && (tmp->attributes[attrib] != -1))
		{
			if (tmp == list.head)
			{
				list.head = list.head->next;
				delete tmp;
				tmp = list.head;
			}
			else
			{
				before->next = tmp->next;
				auto del = tmp->next;
				delete tmp;
				tmp = del;
			}
		}
		else
		{
			before = tmp;
			tmp = tmp->next;
		}
	}
}