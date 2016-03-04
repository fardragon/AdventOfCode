#include <fstream>
#include <string>
#include <iostream>
#include <conio.h>

using namespace std;

struct Op
{
	string source;
	string target;
	Op* next;
};

struct Operations
{
	Op* head = nullptr;
};

struct Molecule
{
	string mol;
	Molecule* next;
};

struct Molecules
{
	Molecule* head = nullptr;
};




void AddOperation(Operations& list, string source, string target);
void AddMolecule(Molecules& list, string mol);
void ParseOps(Operations& list, const string& file);
void ShowOps(Operations list);
void Delete(Operations& list);
void Delete(Molecules& list);
bool IsFound(Molecules list, string what);
void Process(Molecules& mo_list, Operations op_list, string input, int pos);
void ShowMols(Molecules list);

int main()
{
	const string file = "input.txt";
	Operations op_list;
	Molecules mo_list;
	const string inputstring = "HOH";
	ParseOps(op_list, file);
	ShowOps(op_list);

	for (int i = 0; i < inputstring.length(); i++)
	{
		Process(mo_list, op_list, inputstring, i);
	}


	ShowMols(mo_list);

	Delete(mo_list);
	Delete(op_list);
	_getch();
	return 0;
}

void AddOperation(Operations& list, string source, string target)
{
	list.head = new Op{ source,target,list.head };
}

void ParseOps(Operations& list, const string& file)
{
	string currentline, source, target;
	ifstream input(file);
	int pos, counter;
	while (getline(input, currentline))
	{
		pos = 0;
		counter = 0;
		for (counter; counter < currentline.length(); counter++)
		{
			if (currentline[counter] == ' ')
			{
				break;
			}
		}
		source = currentline.substr(pos, counter);
		pos += ++counter;
		for (counter; counter < currentline.length(); counter++)
		{
			if (currentline[counter] == ' ')
			{
				break;
			}
		}
		++counter;
		target = currentline.substr(counter);
		AddOperation(list, source, target);
	}
	input.close();
}

void ShowOps(Operations list)
{
	while (list.head)
	{
		cout << list.head->source << " -> " << list.head->target << endl;
		list.head = list.head->next;
	}
}

void ShowMols(Molecules list)
{
	while (list.head)
	{
		cout << list.head->mol << endl;
		list.head = list.head->next;
	}
}
void Delete(Operations& list)
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

void Delete(Molecules& list)
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



void AddMolecule(Molecules& list, string mol)
{
	list.head = new Molecule{ mol, list.head };
}

bool IsFound(Molecules list, string what)
{
	while (list.head)
	{
		if (list.head->mol == what)
		{
			return true;
		}
		list.head = list.head->next;
	}
	return false;
}

void Process(Molecules& mo_list, Operations op_list, string input, int pos)
{
	string element = input.substr(pos, 1);
	string outputmolecule;
	while (op_list.head)
	{
		if (op_list.head->source == element)
		{
			outputmolecule = input.replace(pos, 1, op_list.head->target);
			if (!IsFound(mo_list,outputmolecule))
			{
				AddMolecule(mo_list, outputmolecule);
			}
		}
		op_list.head = op_list.head->next;
	}

}