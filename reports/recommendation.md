# Where to invest to cut order cycle time

## Summary

Packing is the bottleneck. It takes 63% of the total time orders spend in the process. An average order spends 4.2 hours in Packing, while each of the other stages takes 30 to 40 minutes.

The average actually makes it look better than it is. Packing's P90 is 9.7 hours and its P95 is 15.6 hours, while the other stages have a P90 of about an hour. Late orders are nearly always late because of Packing: about 2,000 orders took more than 24 hours, and 92% of their time was spent in Packing.

I'd start with a Sunday packing shift at WH02 and WH03. After that: cover the hours after the evening shift ends, add staff for 14:00-18:00, and find out what changed at WH03 in mid-September. All four together bring P90 cycle time down from 12.3 hours to 5.4 hours.

## Data

100,000 orders placed between 1 August and 29 October 2026 at four warehouses, each going through five stages (Order Placed, Picked, Packed, Dispatched, Delivered). That's about 500k rows. 99,690 orders had been delivered when the data was pulled. The data is simulated (details in the README).

| Stage | Average | Median | P90 | P95 |
|---|---|---|---|---|
| Order Placed | 30 min | 27 min | 48 min | 57 min |
| Picked | 40 min | 36 min | 65 min | 76 min |
| Packed | 249 min | 117 min | 584 min | 936 min |
| Dispatched | 40 min | 36 min | 64 min | 76 min |
| Delivered | 37 min | 33 min | 59 min | 70 min |

From order to delivery, the median order takes 4.5 hours, the P90 is 12.3 hours and the P95 is 18 hours. About 10,700 orders (11%) took longer than 12 hours.

## Where the Packing delay comes from

1. Sundays at WH02 and WH03. Neither site packs on Sundays. Over 13 Sundays WH02 finished no packing jobs during the day and WH03 finished 35, compared with 3,291 at WH01. Orders that reach packing there on a Sunday wait 16.7 hours on average, until Monday 06:00. Saturday orders wait longer too (6 hours), because the ones that come in Saturday evening run into Sunday. At WH01 and WH04, which do pack on Sundays, Sunday is a normal day (2.4 hours).
2. Overnight. Packing runs from 06:00 to 22:00 at every site. All orders that reach packing between 22:00 and midnight take more than 4 hours, and so do 88% of those arriving between midnight and 06:00. About 15% of orders arrive in these hours.
3. 14:00-18:00. This is the slowest part of the working day at every warehouse. At WH01 and WH04, orders arriving in the afternoon take 2.1-2.3 hours, compared with 1.2 hours in the morning.
4. WH03. It's the slowest site at every time of day (P90 of 16.5 hours, against about 7 hours at WH01 and WH04). It also got worse in mid-September: its weekly average went from about 6.1 to 7.6 hours that week and stayed there. The other three sites stayed at about 3.3 hours.

Delivery region doesn't matter. Packing times differ by region only because each region is mostly served by one warehouse. Within each warehouse, orders going to other regions are packed just as fast (all p > 0.4), and delivering to another region adds only about 9 minutes to the last mile.

## What each fix would do

For each scenario I changed the Packing time of the affected orders and recalculated when they would have been delivered. A same-day miss here means an order placed before 14:00 that wasn't delivered the same day.

| Scenario | Avg packing | P90 cycle | P95 cycle | Orders over 12h | Orders over 24h | Same-day misses |
|---|---|---|---|---|---|---|
| Current | 4.2 h | 12.3 h | 18.0 h | 10,681 | 2,027 | 8.3% |
| A. Night packing cover | 3.0 h | 8.5 h | 15.8 h | 7,171 | 871 | 7.9% |
| B. Sunday shift at WH02 + WH03 | 3.1 h | 10.1 h | 11.5 h | 3,906 | 802 | 1.0% |
| C. Afternoon peak staffing | 3.5 h | 11.2 h | 14.5 h | 7,918 | 1,954 | 6.2% |
| D. WH03 back to pre-September | 3.8 h | 11.6 h | 16.4 h | 9,111 | 1,624 | 7.9% |
| A + B + C + D | 1.5 h | 5.4 h | 6.1 h | 80 | 0 | 0.1% |
| All sites pack like WH01 | 2.3 h | 9.4 h | 10.7 h | 1,257 | 0 | 0.5% |

## Recommendation

1. Add a Sunday packing shift at WH02 and WH03 first. It's one shift a week at two sites, and it takes same-day misses from 8.3% to 1.0% and orders over 12 hours from 10,681 to 3,906. WH01 and WH04 already work Sundays, so there's a model to copy.
2. Then look at the overnight gap. Of the single fixes, night cover improves P90 the most (12.3 to 8.5 hours) and reduces orders over 24 hours from 2,027 to 871. It hardly changes same-day misses, because 84% of overnight arrivals were placed after 14:00 and weren't due the same day anyway. A full night shift costs a lot, so I'd first try keeping one site open until midnight for a month and compare.
3. Add packing staff for 14:00-18:00, for example by moving people from the quieter 18:00-22:00 slot or adding a short overlap shift. On its own this takes same-day misses from 8.3% to 6.2%.
4. Look into WH03 before spending money there. Something changed in the week of 14 September. It was a sudden jump while order volume grew slowly, so it looks like a staffing issue (someone leaving, a bench out of use) rather than demand. Talking to the site lead and checking the rota should explain it.

In numbers: bringing average Packing time down from 4.2 to 1.5 hours would cut P90 cycle time from 12.3 to 5.4 hours and same-day misses from 8.3% to 0.1%. Most of that comes from covering the hours when nobody packs (Sundays and overnight), not from packing faster.

After the changes I'd track three things every week: P90 Packing time per warehouse (not the average), the share of Sunday and overnight orders packed within 4 hours, and same-day misses.

## Limitations

- The data is simulated, so the exact numbers don't mean much on their own. The approach is what would carry over to real data: work out stage times from the event log, look at percentiles as well as averages, break the slow stage down by site, time and day, and then estimate what each fix is worth.
- With 100,000 orders almost every difference is statistically significant, so I focused on how big the effects are.
- The scenarios assume that speeding up Packing doesn't just move the queue to Dispatch or delivery. Those stages look like they have spare capacity (their averages stayed flat for 13 weeks while volume grew by about half), but that needs checking before relying on the combined number.
- The same-day rule (placed before 14:00, delivered the same day) is my own assumption. A different cutoff changes the miss rates but not which fix comes out on top.
