#include <iostream>
#include <ctime>

using namespace std;



int main()
{
	long unsigned int i = 800000;
	long unsigned int  presents = 0;
	clock_t time = clock();
	for (i; true; ++i)
	{
		presents = 0;
		for (int j = 1; j <= i; ++j)
		{
			if ((i % j == 0)&&(i <= j*50)) presents += j * 11;
		}
		//cout << presents << endl;
		//if (i == 831600) system("pause");
		if (presents >= 36000000) break;

	}
	time = clock() - time;
	cout << i << " in: " << time / (double)CLOCKS_PER_SEC << endl;
	


	return i;
}

