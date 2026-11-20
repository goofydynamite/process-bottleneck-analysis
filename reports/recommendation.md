# Where to invest to cut order cycle time

## The short version

Packing is the bottleneck. It takes 63% of all the time orders spend in the process. The average order sits at the packing bench for 4.2 hours, while every other stage takes 30 to 40 minutes.

The average actually understates it. Packing's P90 is 9.7 hours and its P95 is 15.6 hours. The other four stages have a P90 of about an hour. When an order is late, it's almost always because of Packing: for the roughly 2,000 orders that took more than 24 hours end to end, Packing was 92% of their time.

My recommendation is to add a Sunday packing shift at WH02 and WH03 first, then deal with orders that reach packing after the evening shift ends, staff up the 14:00-18:00 window, and find out what changed at WH03 in mid-September. Together, those take P90 cycle time from 12.3 hours to 5.4 hours.

## What I found

Data: 100,000 orders placed between 1 August and 29 October 2026 across four warehouses, five stages each (Order Placed, Picked, Packed, Dispatched, Delivered), about 500k rows. 99,690 were delivered by the time the data was pulled. The data is a simulated event log (see the README), not a real company's.

| Stage | Average | Median | P90 | P95 |
|---|---|---|---|---|
| Order Placed | 30 min | 27 min | 48 min | 57 min |
| Picked | 40 min | 36 min | 65 min | 76 min |
| Packed | 249 min | 117 min | 584 min | 936 min |
| Dispatched | 40 min | 36 min | 64 min | 76 min |
| Delivered | 37 min | 33 min | 59 min | 70 min |

End to end, the median order takes 4.5 hours but the P90 is 12.3 hours and the P95 is 18 hours. About 10,700 orders (11%) took over 12 hours.

The Packing problem isn't spread evenly. It comes from four places:

1. Sundays at WH02 and WH03. Neither warehouse runs a Sunday packing shift: across 13 Sundays, WH02 finished no packing jobs during the day and WH03 finished 35, against 3,291 at WH01. Orders that reach their benches on a Sunday wait 16.7 hours on average, until Monday 06:00. Saturday arrivals are hit too (6 hours), because evening orders roll into the Sunday gap. At WH01 and WH04, which pack on Sundays, Sunday looks like any other day (2.4 hours).
2. Overnight. Packing runs 06:00-22:00 everywhere. Every order that reaches packing between 22:00 and midnight takes over 4 hours, and 88% of those arriving between midnight and 06:00 do. That's 15% of orders.
3. The 14:00-18:00 window. It's the slowest daytime window at every warehouse. At WH01 and WH04, afternoon arrivals take 2.1-2.3 hours against 1.2 hours in the morning.
4. WH03. It's the slowest warehouse in every time window (P90 16.5 hours vs about 7 hours at WH01 and WH04), and it got worse from mid-September. Its weekly average packing time stepped up from about 6.1 to 7.6 hours that week and stayed there, while the other three warehouses stayed flat at 3.3 hours.

The delivery region doesn't matter. Packing times differ by region only because each region is mostly served by one warehouse. Inside each warehouse, orders going to other regions pack no slower than home-region orders (all p > 0.4), and cross-region deliveries only add about 9 minutes to the last mile.

## What fixing it would be worth

I replaced each affected order's packing time with what it would have been under each fix and recomputed its delivery time. "Same-day miss" means an order placed before 14:00 that wasn't delivered the same calendar day.

| Scenario | Avg packing | P90 cycle | P95 cycle | Orders over 12h | Orders over 24h | Same-day misses |
|---|---|---|---|---|---|---|
| Current | 4.2 h | 12.3 h | 18.0 h | 10,681 | 2,027 | 8.3% |
| A. Night packing cover | 3.0 h | 8.5 h | 15.8 h | 7,171 | 871 | 7.9% |
| B. Sunday shift at WH02 + WH03 | 3.1 h | 10.1 h | 11.5 h | 3,906 | 802 | 1.0% |
| C. Afternoon peak staffing | 3.5 h | 11.2 h | 14.5 h | 7,918 | 1,954 | 6.2% |
| D. WH03 back to pre-September | 3.8 h | 11.6 h | 16.4 h | 9,111 | 1,624 | 7.9% |
| A + B + C + D | 1.5 h | 5.4 h | 6.1 h | 80 | 0 | 0.1% |
| All warehouses pack like WH01 | 2.3 h | 9.4 h | 10.7 h | 1,257 | 0 | 0.5% |

## Recommendation

1. Start with a Sunday packing shift at WH02 and WH03. One shift a week at two sites cuts same-day misses from 8.3% to 1.0% (88% fewer) and orders over 12 hours by almost two thirds (10,681 to 3,906). WH01 and WH04 already do this, so the operating model exists.
2. Deal with the overnight gap next. Night cover gives the biggest P90 improvement of any single fix (12.3 to 8.5 hours) and cuts orders over 24 hours from 2,027 to 871. It barely moves same-day misses, because 84% of night arrivals were placed after 14:00 and weren't promised same day anyway. A full night shift is expensive, so I'd first test extending the evening shift to midnight at one site for a month and measure the change.
3. Add packing capacity for 14:00-18:00, either by moving staff from the quieter 18:00-22:00 window or with a short overlap shift. On its own that cuts same-day misses from 8.3% to 6.2%.
4. Investigate WH03 before spending money there. Something changed in the week of 14 September. The step is sudden while order volume grew gradually, which points to staffing (a packer leaving, a bench out of action) rather than demand. A conversation with the site lead and a look at the rota should answer it.

The headline: cutting average Packing time from 4.2 hours to 1.5 hours would cut P90 total cycle time from 12.3 hours to 5.4 hours and same-day misses from 8.3% to 0.1%. Most of that comes from covering the hours nobody is packing (Sundays and overnight), not from making packers faster.

What I'd track after the change: weekly P90 Packing time per warehouse (not the average), the share of Sunday and overnight arrivals packed within 4 hours, and same-day misses.

## Caveats

- The data is simulated, so the specific numbers are illustrative. The method (stage durations from an event log, percentiles over averages, slicing the bottleneck by site, time and day, then pricing fixes) is what carries over to a real log.
- With 100,000 orders almost every difference is statistically significant, so I've focused on the size of the effects rather than p-values.
- The scenarios assume that clearing one queue doesn't create a new one further down. Dispatch and last mile look like they have spare capacity (their averages are flat across all 13 weeks while volume grew by half), but that should be checked before relying on the combined figure.
- The same-day rule (placed before 14:00, delivered the same day) is my assumption. Changing the cutoff changes the miss rate but not the ranking of the fixes.
