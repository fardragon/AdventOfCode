#include <iostream>
#include <bitset>
#include <list>
#include <fstream>
#define SIZE 28
#define COMPARTMENTS 4


using namespace std;

void subsets(int S[], int n);



struct Subset
{
	int number;
	list<int> packages;
};



int main()
{
	const int packages[SIZE] = { 1,3,5,11,13,17,19,23,29,31,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113 };
	int weight = 0;
	for (int i = 0; i < SIZE; i++)
	{
		weight += packages[i];
	}
	weight /= COMPARTMENTS;


	list<Subset> subsets;
	int set_number = 1;
	int temporary_weight;
	Subset temporary_set;
	string binary;
	int min_size = SIZE;


	for (int i = 1; i < pow(2, SIZE); i++)
	{
		temporary_set.number = set_number;
		temporary_set.packages.clear();
		temporary_weight = 0;
		binary = bitset<SIZE>(i).to_string();
		for (int j = 0; j < binary.length(); j++)
		{
			if (binary[j] == '1') temporary_set.packages.push_back(packages[j]);
		}
		for (list<int>::iterator j = temporary_set.packages.begin(); j != temporary_set.packages.end(); ++j)
		{
			temporary_weight += *j;
		}

		if ((temporary_weight == weight)&&(temporary_set.packages.size()<=min_size))
		{
			subsets.push_back(temporary_set);
			if (temporary_set.packages.size() < min_size) min_size = temporary_set.packages.size();
			set_number++;
		}
	}


	long long min_QE = _LLONG_MAX;
	int minpos = 1;

	for (list<Subset>::iterator i = subsets.begin(); i != subsets.end(); ++i)
		{
		long long QE = 1;
		
		if (i->packages.size() == min_size)
		{
			for (list<int>::iterator j = i->packages.begin(); j != i->packages.end(); ++j)
			{
				QE *= *j;
			}
			if (QE < min_QE)
			{
				minpos = i->number;
				min_QE = QE;
			}
		}
		}


	for (list<Subset>::iterator i = subsets.begin(); i != subsets.end(); ++i)
	{

		if (i->number == minpos)
		{
			cout << "Set no: " << minpos << endl;
			for (list<int>::iterator j = i->packages.begin(); j != i->packages.end(); ++j)
			{
				cout << *j << " " << endl;
			}
			cout << "Size: " << i->packages.size() << " QE: " << min_QE << endl;

		}
	}

	return 0;
}

