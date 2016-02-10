#include <iostream>
#include <fstream>
#include <string>

using namespace std;

enum class Operation { hlf, tpl, inc, jmp, jie, jio};

struct Command
{
	Operation operation;
	char reg;
	int target;
	Command* previous;
	Command* next;
};

void Add_Commands(Command* &list, const string & file_name);
void Add(Command* &head, Operation op, int target, char reg);
void Delete(Command* &head);
void Process(Command* head, int &regA, int &regB);
Command* Move(Command* current, int target);

int main()
{
	Command* list = nullptr;
	Add_Commands(list, "input.txt");
	int regA = 0, regB = 0;
	Process(list, regA, regB);
	cout << "Register A: " << regA << " Register B: " << regB << endl;
	Delete(list);
	return 0;
}


void Add_Commands(Command* &list, const string & file_name)
{
	ifstream input(file_name);
	string line;
	char reg;
	int target;
	Operation op;
	while (getline(input, line))
	{
		if (line.substr(0, 3) == "hlf")
		{
			op = Operation::hlf;
			target = 0;
			reg = line[4];
		}
		else if (line.substr(0, 3) == "tpl")
		{
			op = Operation::tpl;
			target = 0;
			reg = line[4];
		}
		else if (line.substr(0, 3) == "inc")
		{
			op = Operation::inc;
			target = 0;
			reg = line[4];
		}
		else if (line.substr(0, 3) == "jmp")
		{
			op = Operation::jmp;
			target = stoi(line.substr(4));
			reg = '0';
		}
		else if (line.substr(0, 3) == "jie")
		{
			op = Operation::jie;
			target = stoi(line.substr(6));
			reg = line[4];
		}
		else if (line.substr(0, 3) == "jio")
		{
			op = Operation::jio;
			target = stoi(line.substr(6));
			reg = line[4];
		}
		Add(list, op, target, reg);
	}
	input.close();

}

void Add(Command* &head,Operation op, int target, char reg)
{
	if (head == nullptr)
	{
		head = new Command{ op,reg,target,nullptr,nullptr };
		return;
	}
	auto tmp = head;
	while (tmp->next != nullptr)
	{
		tmp = tmp->next;
	}
	tmp->next = new Command{ op,reg,target,tmp,nullptr };
}

void Delete(Command* &head)
{
	auto tmp = head;
	while (head)
	{
		tmp = head;
		head = head->next;
		delete tmp;
	}
	head = nullptr;
}

void Process(Command* head, int &regA, int &regB)
{
	while (head)
	{
		switch (head->operation)
		{
		case Operation::hlf:
			if (head->reg == 'a') regA /= 2;
			else regB /= 2;
			head = head->next;
			break;
		case Operation::inc:
			if (head->reg == 'a') ++regA;
			else ++regB;
			head = head->next;
			break;
		case Operation::tpl:
			if (head->reg == 'a') regA*=3;
			else regB*=3;
			head = head->next;
			break;
		case Operation::jmp:
			head = Move(head, head->target);
			break;
		case Operation::jie:
			if (head->reg == 'a')
			{
				if (regA % 2 == 0)
				{
					head = Move(head, head->target);
				}
				else head = head->next;
			}
			else if (regB % 2 == 0)
			{
				head = Move(head, head->target);
			}
			else head = head->next;
			break;
		case Operation::jio:
			if (head->reg == 'a')
			{
				if (regA  == 1)
				{
					head = Move(head, head->target);
				}
				else head = head->next;
			}
			else if (regB == 1)
			{
				head = Move(head, head->target);
			}
			else head = head->next;
			break;
		}
	}
	return;
}

Command* Move(Command* current, int target)
{
	bool forward = true;
	if (target < 0)
	{
		forward = false;
		target = target * -1;
	}
	auto tmp = current;
	if (forward)
	{
		for (int i = 0; i < target; ++i)
		{
			tmp = tmp->next;
		}
	}
	else
	{
		for (int i = 0; i < target; ++i)
		{
			tmp = tmp->previous;
		}
	}
	return tmp;
}