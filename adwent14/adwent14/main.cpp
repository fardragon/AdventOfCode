#include <iostream>
#include <fstream>
#include <string>
#include <conio.h>
#include <iomanip>

using namespace std;

struct Reindeer
{
	string name;
	int distance;
	int speed;
	int restingtimer;
	int flyingtimer;
	int durability;
	int restneed;
	bool resting;
	Reindeer* next;
	int points;
};

struct Reindeers
{
	Reindeer* head = nullptr;
};



void ParseFile(const string& filename, Reindeers& list);
void Add(Reindeers& list, string name,int speed, int durability, int restneed);
string GetName(string line);
int GetSpeed(string line);
int GetDurability(string line);
int GetRest(string line);
void Timer(Reindeers& list, int racetime);
void Race(Reindeers& list);
void Finish(Reindeers& list);
void Delete(Reindeers &list);
int CheckLead(Reindeers list);
void AwardPoints(Reindeers& list, int lead);


int main()
{
	const int racetime = 2503;
	const string filename = "input.txt";
	Reindeers list;
	ParseFile(filename, list);
	Timer(list, racetime);
	Finish(list);
	Delete(list);
	_getch();
	return 0;
}

void Add(Reindeers& list, string name, int speed, int durability, int restneed)
{
	list.head = new Reindeer
	{
		name, // name
		0, //distance
		speed, // speed
		0, //restingtimer
		0, //flyingtimer
		durability, // durability
		restneed, //restneed
		false, // resting
		list.head, // next
		0 //points
	};
	
}

string GetName(string line)
{
	int pos = 0;
	for (pos; pos < line.length(); pos++)
	{
		if (line[pos] == ' ')
		{
			break;
		}
	}
	return line.substr(0, pos);
}

int GetSpeed(string line)
{

	int pos = line.find("fly");
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

int GetDurability(string line)
{

	int pos = line.find("for");
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

int GetRest(string line)
{
	int pos = line.find(",");
	pos = line.find("for",pos);
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

void ParseFile(const string& filename, Reindeers& list)
{
	string currentline, name;
	int speed, durability, restneed;
	ifstream input(filename);
	while (getline(input, currentline))
	{
		name = GetName(currentline);
		speed = GetSpeed(currentline);
		durability = GetDurability(currentline);
		restneed = GetRest(currentline);
		Add(list, name, speed, durability, restneed);
	}
	input.close();

}

void Race(Reindeers& list)
{
	auto reindeer = list.head;
	while (reindeer)
	{
		if (reindeer->resting)
		{
			++reindeer->restingtimer;
			if (reindeer->restingtimer == reindeer->restneed)
			{
				reindeer->resting = false;
				reindeer->restingtimer = 0;
			}
		}
		else
		{
			reindeer->distance += reindeer->speed;
			++reindeer->flyingtimer;
			if (reindeer->flyingtimer == reindeer->durability)
			{
				reindeer->resting = true;
				reindeer->flyingtimer = 0;
			}
		}
		reindeer = reindeer->next;
	}
}

void Timer(Reindeers& list, int racetime)
{
	int lead;
	for (int i = 0; i < racetime; i++)
	{
		Race(list);
		lead = CheckLead(list);
		AwardPoints(list,lead);
	}
	return;
}

void Finish(Reindeers& list)
{
	auto reindeer = list.head;
	while (reindeer)
	{
		cout << setw(7);
		cout << reindeer->name << ": " << reindeer->distance << "km points: " << reindeer->points <<endl;
		reindeer = reindeer->next;
	}

}

void Delete(Reindeers &list)
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

int CheckLead(Reindeers list)
{
	int lead = 0;
	while (list.head)
	{
		if (list.head->distance > lead)
		{
			lead = list.head->distance;
		}
		list.head = list.head->next;
	}
	return lead;
}

void AwardPoints(Reindeers& list, int lead)
{
	auto reindeer = list.head;
	while (reindeer)
	{
		if (reindeer->distance == lead)
		{
			++reindeer->points;
		}
		reindeer = reindeer->next;
	}
}