#include <iostream>
#include <fstream>

using namespace std;



int main()
{

	int i = 1;
	int presents = 0;
	for (i; true; ++i)
	{
		presents = 0;
		for (int j = 1; j <= i; ++j)
		{
			if (i % j == 0) presents += j * 10;
		}
		cout << presents << endl;
		if (presents >= 36000000) break;

	}
	cout << i;















	system("pause");
	return i;
}

