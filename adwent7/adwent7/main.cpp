#include <iostream>
#include <fstream>
#include <string>
#include <stdexcept>
#include <conio.h>
#include <stdint.h>

using namespace std;

struct Wire
{
	string name = "Z";
	uint16_t value;
};

int wiresnum = 0;
void AddWire(Wire* &wires, string arg,int value);
int Select(string & line);
void CopyFile(const string &file1,const string & file2);
bool IsFound(Wire* wires, const string & look);
void CutEnter(string & line, string & arg1, string & target1);
bool Enter(Wire* &wires, string arg, string target);
bool Empty(string file);
bool IsNumber(string arg);
void CutThree(string& line, string& arg1, string& arg2, string& target);
bool AndFc(Wire* wires, string arg1, string arg2, string target);
bool OrFc(Wire* wires, string arg1, string arg2, string target);
bool Rshift(Wire* wires, string arg1, string arg2, string target);
bool Lshift(Wire* wires, string arg1, string arg2, string target);
void CutNot(string& line, string& arg1, string& target);
bool NotFc(Wire* &wires, string arg, string target);

int main()
{
	const int n = 1000;
	CopyFile("input.txt","todo.txt");
	string line;
	int gate;
	Wire* wires = nullptr;
	wires = new Wire[n];
	bool done;
	while (!Empty("todo.txt"))
	{
		ifstream todo("todo.txt");
		ofstream notdone("notdone.txt", ios::trunc);
		while (getline(todo, line))
		{
			gate = Select(line);
			switch (gate)
			{
			case 0: //Enter
			{
				string arg, target;
				CutEnter(line, arg, target);
				done = Enter(wires, arg, target);
				break;
			}
			case 1: //AND
			{
				string arg1, arg2, target;
				CutThree(line, arg1, arg2, target);
				done = AndFc(wires, arg1, arg2, target);
				break;
			}
			case 2: //OR
			{
				string arg1, arg2, target;
				CutThree(line, arg1, arg2, target);
				done = OrFc(wires, arg1, arg2, target);
				break;
			}
			case 3: //NOT
			{
				string arg1, target;
				CutNot(line, arg1, target);
				done = NotFc(wires, arg1, target);
				break;
			}
			case 4: //RSHIFT
			{
				string arg1, arg2, target;
				CutThree(line, arg1, arg2, target);
				done = Rshift(wires, arg1, arg2, target);
				break;
			}
			case 5: //LSHIFT
			{
				string arg1, arg2, target;
				CutThree(line, arg1, arg2, target);
				done = Lshift(wires, arg1, arg2, target);
				break;
			}
			}
			if (!done)
			{
				notdone << line << endl;
			}
		}
		todo.close();
		notdone.close();
		CopyFile("notdone.txt", "todo.txt");
	}


	for (int i = 0; i < wiresnum; i++) cout << wires[i].name << " " << wires[i].value << endl;

	delete[] wires;
	_getch();
	return 0;
}

bool Empty(string file)
{
	ifstream pFile(file);
	if (pFile.peek() == std::ifstream::traits_type::eof())
	{
		pFile.close();
		return true;
	}
	else
	{
		pFile.close();
		return false;
	}
}

void AddWire(Wire* &wires, string arg, int value)
{
	wires[wiresnum].name = arg;
	wires[wiresnum].value = value;
	++wiresnum;
	return;
}

bool IsFound(Wire* wires, const string & look)
{
	for (int i = 0; i < wiresnum; i++)
	{
		if (wires[i].name == look)
		{
			return true;
		}
	}
	return false;
}

void CopyFile(const string &file1, const string & file2)
{
	ifstream input(file1);
	ofstream output(file2, ios::trunc);
	string temp;
	while (getline(input,temp))
	{
		output << temp << endl;
	}
	input.close();
	output.close();
	return;
}

bool is_empty(ifstream& file)
{
	return file.peek() == std::ifstream::traits_type::eof();
}

int Select(string & line)
{
	if (line.find("AND") != string::npos)
	{
		return 1;
	}
	if (line.find("OR") != string::npos)
	{
		return 2;
	}
	if (line.find("NOT") != string::npos)
	{
		return 3;
	}
	if (line.find("RSHIFT") != string::npos)
	{
		return 4;
	}
	if (line.find("LSHIFT") != string::npos)
	{
		return 5;
	}
	return 0;
}

void CutEnter(string & line, string & arg1, string & target1)
{
	int tmp = 0;
	for (tmp; tmp < line.length(); tmp++)
	{
		if (line[tmp] == ' ')
		{
			break;
		}
	}
	arg1 = line.substr(0,tmp);
	for (tmp; tmp < line.length(); tmp++)
	{
		if ((line[tmp] >= 97) && (line[tmp <= 122]))
		{
			break;
		}
	}
	target1 = line.substr(tmp);
	return;
}

bool Enter(Wire* &wires, string arg, string target)
{
	try
	{
		int argument = stoi(arg);
	}
	catch (invalid_argument)
	{
		if (IsFound(wires, arg))
		{
			if (IsFound(wires, target))
			{
				int target_pos, argument_pos;
				for (int i = 0; i < wiresnum; i++)
				{
					if (wires[i].name == arg) argument_pos = i;
					if (wires[i].name == target) target_pos = i;
				}
				wires[target_pos].value = wires[argument_pos].value;
				return true;
			}
			else
			{
				int argument_pos;
				for (int i = 0; i < wiresnum; i++)
				{
					if (wires[i].name == arg)
					{
						argument_pos = i;
						break;
					}
				}
				AddWire(wires, target, wires[argument_pos].value);
				return true;
			}

		}
		return false;
	}
	int argument = stoi(arg);
	if (IsFound(wires, target))
	{
		int target_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == target) target_pos = i;
		}
		wires[target_pos].value = argument;
		return true;
	}
	AddWire(wires, target, argument);
	return true;
}

bool IsNumber(string arg)
{
	for (int i = 0; i < arg.length(); i++)
	{
		if (!((arg[i] >= 48) && (arg[i] <= 57)))
		{
			if (arg[i] == ' ')
			{
				continue;
			}
			return false;
		}
	}
	return true;
}

void CutThree(string& line, string& arg1, string& arg2, string& target)
{
	int tmp = 0;
	for (tmp; tmp < line.length(); tmp++)
	{
		if (line[tmp] == ' ')
		{
			break;
		}
	}
	arg1 = line.substr(0, tmp);
	++tmp;
	for (tmp; tmp < line.length(); tmp++)
	{
		if (line[tmp] == ' ')
		{
			break;
		}
	}
	++tmp;
	for (tmp; tmp < line.length(); tmp++)
	{
		if (line[tmp] == ' ')
		{
			break;
		}
		arg2 += line[tmp];
	}
	for (tmp; tmp < line.length(); tmp++)
	{
		if ((line[tmp] >= 97) && (line[tmp <= 122]))
		{
			break;
		}
	}
	target = line.substr(tmp);
	return;
}

bool AndFc(Wire* wires, string arg1, string arg2, string target)
{
	if ((IsNumber(arg1)) && (IsNumber(arg2)))
	{
		int argument1 = stoi(arg1);
		int argument2 = stoi(arg2);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 & argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 & argument2);
			return true;
		}
	}
	if ((!IsNumber(arg1)) && (IsNumber(arg2)))
	{
		if (!IsFound(wires, arg1))
		{
			return false;
		}
		int argument_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == arg1)
			{
				argument_pos = i;
				break;
			}
		}
		int argument1 = wires[argument_pos].value;
		int argument2 = stoi(arg2);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 & argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 & argument2);
			return true;
		}
	}
	if ((!IsNumber(arg2)) && (IsNumber(arg1)))
	{
		if (!IsFound(wires, arg2))
		{
			return false;
		}
		int argument_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == arg2)
			{
				argument_pos = i;
				break;
			}
		}
		int argument1 = wires[argument_pos].value;
		int argument2 = stoi(arg1);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 & argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 & argument2);
			return true;
		}
	}

	if (!IsFound(wires, arg1)) return false;
	if (!IsFound(wires, arg2)) return false;
	int argument1_pos, argument2_pos;
	for (int i = 0; i < wiresnum; i++)
	{
		if (wires[i].name == arg1)
		{
			argument1_pos = i;
		}
		if (wires[i].name == arg2)
		{
			argument2_pos = i;
		}
	}
	int argument1 = wires[argument1_pos].value;
	int argument2 = wires[argument2_pos].value;
	if (IsFound(wires, target))
	{
		int target_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == target)
			{
				target_pos = i;
				break;
			}
		}
		wires[target_pos].value = argument1 & argument2;
		return true;

	}
	else
	{
		AddWire(wires, target, argument1 & argument2);
		return true;
	}
}

bool OrFc(Wire* wires, string arg1, string arg2, string target)
{
	if ((IsNumber(arg1)) && (IsNumber(arg2)))
	{
		int argument1 = stoi(arg1);
		int argument2 = stoi(arg2);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 | argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 | argument2);
			return true;
		}
	}
	if ((!IsNumber(arg1)) && (IsNumber(arg2)))
	{
		if (!IsFound(wires, arg1))
		{
			return false;
		}
		int argument_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == arg1)
			{
				argument_pos = i;
				break;
			}
		}
		int argument1 = wires[argument_pos].value;
		int argument2 = stoi(arg2);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 | argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 | argument2);
			return true;
		}
	}
	if ((!IsNumber(arg2)) && (IsNumber(arg1)))
	{
		if (!IsFound(wires, arg2))
		{
			return false;
		}
		int argument_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == arg2)
			{
				argument_pos = i;
				break;
			}
		}
		int argument1 = wires[argument_pos].value;
		int argument2 = stoi(arg1);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 | argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 | argument2);
			return true;
		}
	}

	if (!IsFound(wires, arg1)) return false;
	if (!IsFound(wires, arg2)) return false;
	int argument1_pos, argument2_pos;
	for (int i = 0; i < wiresnum; i++)
	{
		if (wires[i].name == arg1)
		{
			argument1_pos = i;
		}
		if (wires[i].name == arg2)
		{
			argument2_pos = i;
		}
	}
	int argument1 = wires[argument1_pos].value;
	int argument2 = wires[argument2_pos].value;
	if (IsFound(wires, target))
	{
		int target_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == target)
			{
				target_pos = i;
				break;
			}
		}
		wires[target_pos].value = argument1 | argument2;
		return true;

	}
	else
	{
		AddWire(wires, target, argument1 | argument2);
		return true;
	}
}

bool Rshift(Wire* wires, string arg1, string arg2, string target)
{
	if ((IsNumber(arg1)) && (IsNumber(arg2)))
	{
		int argument1 = stoi(arg1);
		int argument2 = stoi(arg2);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 >> argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 >> argument2);
			return true;
		}
	}
	if ((!IsNumber(arg1)) && (IsNumber(arg2)))
	{
		if (!IsFound(wires, arg1))
		{
			return false;
		}
		int argument_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == arg1)
			{
				argument_pos = i;
				break;
			}
		}
		int argument1 = wires[argument_pos].value;
		int argument2 = stoi(arg2);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 >> argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 >> argument2);
			return true;
		}
	}
	if ((!IsNumber(arg2)) && (IsNumber(arg1)))
	{
		if (!IsFound(wires, arg2))
		{
			return false;
		}
		int argument_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == arg2)
			{
				argument_pos = i;
				break;
			}
		}
		int argument1 = wires[argument_pos].value;
		int argument2 = stoi(arg1);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 >> argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 >> argument2);
			return true;
		}
	}

	if (!IsFound(wires, arg1)) return false;
	if (!IsFound(wires, arg2)) return false;
	int argument1_pos, argument2_pos;
	for (int i = 0; i < wiresnum; i++)
	{
		if (wires[i].name == arg1)
		{
			argument1_pos = i;
		}
		if (wires[i].name == arg2)
		{
			argument2_pos = i;
		}
	}
	int argument1 = wires[argument1_pos].value;
	int argument2 = wires[argument2_pos].value;
	if (IsFound(wires, target))
	{
		int target_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == target)
			{
				target_pos = i;
				break;
			}
		}
		wires[target_pos].value = argument1 >> argument2;
		return true;

	}
	else
	{
		AddWire(wires, target, argument1 >> argument2);
		return true;
	}
}

bool Lshift(Wire* wires, string arg1, string arg2, string target)
{
	if ((IsNumber(arg1)) && (IsNumber(arg2)))
	{
		int argument1 = stoi(arg1);
		int argument2 = stoi(arg2);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 << argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 << argument2);
			return true;
		}
	}
	if ((!IsNumber(arg1)) && (IsNumber(arg2)))
	{
		if (!IsFound(wires, arg1))
		{
			return false;
		}
		int argument_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == arg1)
			{
				argument_pos = i;
				break;
			}
		}
		int argument1 = wires[argument_pos].value;
		int argument2 = stoi(arg2);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 << argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 << argument2);
			return true;
		}
	}
	if ((!IsNumber(arg2)) && (IsNumber(arg1)))
	{
		if (!IsFound(wires, arg2))
		{
			return false;
		}
		int argument_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == arg2)
			{
				argument_pos = i;
				break;
			}
		}
		int argument1 = wires[argument_pos].value;
		int argument2 = stoi(arg1);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = argument1 << argument2;
			return true;

		}
		else
		{
			AddWire(wires, target, argument1 << argument2);
			return true;
		}
	}

	if (!IsFound(wires, arg1)) return false;
	if (!IsFound(wires, arg2)) return false;
	int argument1_pos, argument2_pos;
	for (int i = 0; i < wiresnum; i++)
	{
		if (wires[i].name == arg1)
		{
			argument1_pos = i;
		}
		if (wires[i].name == arg2)
		{
			argument2_pos = i;
		}
	}
	int argument1 = wires[argument1_pos].value;
	int argument2 = wires[argument2_pos].value;
	if (IsFound(wires, target))
	{
		int target_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == target)
			{
				target_pos = i;
				break;
			}
		}
		wires[target_pos].value = argument1 << argument2;
		return true;

	}
	else
	{
		AddWire(wires, target, argument1 << argument2);
		return true;
	}
}

void CutNot(string& line, string& arg1, string& target)
{
	int tmp = 4;
	for (tmp; tmp < line.length(); tmp++)
	{
		if (line[tmp] == ' ')
		{
			break;
		}
	}
	arg1 = line.substr(4, tmp-4);
	for (tmp; tmp < line.length(); tmp++)
	{
		if ((line[tmp] >= 97) && (line[tmp <= 122]))
		{
			break;
		}
	}
	target = line.substr(tmp);
	return;
}

bool NotFc(Wire* &wires, string arg, string target)
{
	if (IsNumber(arg))
	{
		int argument = stoi(arg);
		if (IsFound(wires, target))
		{
			int target_pos;
			for (int i = 0; i < wiresnum; i++)
			{
				if (wires[i].name == target)
				{
					target_pos = i;
					break;
				}
			}
			wires[target_pos].value = ~argument;
			return true;

		}
		else
		{
			AddWire(wires, target, ~argument);
			return true;
		}

	}
	if (!IsFound(wires, arg)) return false;
	int argument_pos;
	for (int i = 0; i < wiresnum; i++)
	{
		if (wires[i].name == arg)
		{
			argument_pos = i;
			break;
		}
	}
	int argument = wires[argument_pos].value;
	if (IsFound(wires, target))
	{
		int target_pos;
		for (int i = 0; i < wiresnum; i++)
		{
			if (wires[i].name == target)
			{
				target_pos = i;
				break;
			}
		}
		wires[target_pos].value = ~argument;
		return true;

	}
	else
	{
		AddWire(wires, target, ~argument);
		return true;
	}
}