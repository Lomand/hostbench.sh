# hostbench.sh
Hostbench is a linux server benchmark created to help developers measure the performance of linux servers and compare it with other submissions.
## How to benchmark your server
First of all, go to the [hostbench.io website](https://hostbench.io/) and click on "Benchmark your VPS" on top right corner.
After that, you will be asked about the name of your VPS provider as well as the price you charged monthly for using it.
After filling information about your provider, you will get the code that you should execute on your VPS.


```
 wget -N http://submit.hostbench.io -O hb.sh && sudo bash hb.sh 'YOUR_BENCH_ID'
```
You will resive a link to the benchmark summary on your email.
