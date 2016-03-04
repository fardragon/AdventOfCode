#include <iostream>
#include <iomanip> 


using namespace std;

const int N = 8000;



int main()
{
	uint64_t** codes = new uint64_t* [N];
	for (int i = 0; i < N; i++)
	{
		codes[i] = new uint64_t[N];
	}

	for (int i = 0; i < N; i++)
		for (int j = 0; j < N; j++)
		{
			codes[i][j] = 0;
		}

	codes[0][0] = 20151125;
	uint64_t previous = codes[0][0];

	int xpos = 0, ypos = 1, yrow = 1;
	while (yrow < N)
	{
		
		previous = (previous*252533) % 33554393;
		codes[xpos][ypos] = previous;
		if (ypos == 0)
		{
			++yrow;
			ypos = yrow;
			xpos = 0;
		}
		else
		{
			++xpos;
			--ypos;
		}
	}


	cout << codes[3083-1][2978-1] << endl;
	cout << codes[2978-1][3083-1] << endl;
	system("pause");

	for (int i = 0; i < N; i++)
	{
		delete[] codes[i];
	}
	delete codes;
	return 0;
}