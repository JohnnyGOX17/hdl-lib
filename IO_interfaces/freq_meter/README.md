# Frequency Meter

Using a known reference clock (`ref_clk`) frequency, the number of test clock (`test_clk`) cycles are counted, up to a second of `ref_clk` time. Thus, the number of `test_clk` cycles measured in one second time frame is directly the measured frequency. This count value in the `test_clk` domain is CDC'ed to the `ref_clk` domain using a gray counter to minimize transitions. The counter reset logic is then hand-shake back in case of large frequency differences between test and reference clocks.

