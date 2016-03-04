#include <iostream>
#include <string>
#include <fstream>
#include <conio.h>
#include "json.h"

using namespace std;

string input;


int main()
{
	ifstream file("json.txt");
	getline(file, input);
	file.close();
	json::Object my_data = json::Deserialize(input);
	for (json::Object::ValueMap::iterator it = my_data.begin(); it != my_data.end(); ++it)
	{
		cout << it->first << " " << it->second.ToInt() << endl;
	}











	_getch();
	return 0;
}