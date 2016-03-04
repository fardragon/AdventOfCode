#include <iostream>
#include <bitset>
#include <list>
#define SIZE 20
#define LITERS 150

using namespace std;



struct Subset
{
	int number;
	list<int> packages;
};






int main()
{
	const int containers[SIZE] = { 11,30,47,31,32,36,3,1,5,3,32,36,15,11,46,26,28,1,19,3 };


	list<Subset> subsets;
	int set_number = 1;
	int temporary_liters;
	Subset temporary_set;
	string binary;
	int min_container = INT64_MAX;

	for (int i = 1; i < pow(2, SIZE); i++)
	{
		temporary_set.number = set_number;
		temporary_set.packages.clear();
		temporary_liters = 0;
		binary = bitset<SIZE>(i).to_string();
		for (int j = 0; j < binary.length(); j++)
		{
			if (binary[j] == '1') temporary_set.packages.push_back(containers[j]);
		}
		for (list<int>::iterator j = temporary_set.packages.begin(); j != temporary_set.packages.end(); ++j)
		{
			temporary_liters += *j;
		}

		if (temporary_liters == LITERS)
		{
			if (min_container > temporary_set.packages.size())
			{
				min_container = temporary_set.packages.size();
			}
			subsets.push_back(temporary_set);
			set_number++;
			
		}
	}

	int min_counter=0;

	for (list<Subset>::iterator i = subsets.begin(); i != subsets.end(); ++i)
	{
		if (i->packages.size() == min_container)
		{
			++min_counter;
		}
	}


	cout << "Ways: " << subsets.size() << endl;
	cout << "Minimum: " << min_container << " in " << min_counter << " ways" << endl;









	return 0;
}