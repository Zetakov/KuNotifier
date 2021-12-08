#!/bin/bash

# Edit this to be an e-mail or sms gateway
notification_email="6125551212@txt.att.net"


HODL=${1^^}
PAIR=${2^^}
sell_point=$3
above=0
ticker_url="https://api.kucoin.com/api/v1/market/orderbook/level1?symbol="

if [[ -z $4 ]]; then
	spread=1
else
	spread=$4
fi

help_screen() {
	echo "KuNotifier v1.0 by  ζ(Kₒᵥ)"
        echo "Usage: $0 coin1 coin2 sell_point spread [options]"
        echo " "
        echo "Options: "
        echo "          -a  (above price)"
        echo " "
        echo "          spread refers to the increment in which to continually send notifications "
        echo "          i.e., if notifications happen at ADA = 2.05 and spread = 0.1, the next notification"
        echo "          will be sent at ADA = 2.15, if -a is applied, or ADA = 1.95 if not supplying -a"
	echo " "
	echo "NOTE: "
	echo "    edit the 'notification_email' variable in the script to send SMS text to your phone"
	echo "    when the sell-point is reached and for each subsequent spread."
        exit

}

if [[ $# -lt 3 ]]; then
	help_screen
fi

while [ "$#" -gt 0 ]; do
        key=${1}

        case ${key} in
                -a|--above)
                        above=1
                        shift
                        ;;
                -h|--help)
                        help_screen
                        shift
                        ;;
                				
                *)
                        shift
                        ;;
        esac
done


while true; do
        clear
        json=`curl -s -k -X GET "$ticker_url$HODL"-"$PAIR"`
        price_point=`echo $json | jq '.data.price'  | sed -e 's/\"//g'`
        bestBid=`echo $json | jq '.data.bestBid' | sed -e 's/\"//g'`
        bestAsk=`echo $json | jq '.data.bestAsk' | sed -e 's/\"//g'`
        bestBidSize=`echo $json | jq '.data.bestBidSize' | sed -e 's/\"//g'`
        bestAskSize=`echo $json | jq '.data.bestAskSize' | sed -e 's/\"//g'`
        echo "============================KuCoin============================="
        echo "                           $HODL/$PAIR"
        echo " "
        echo "          Notify:         $sell_point"
        echo " "
        echo "          Price:          $price_point"
        echo "          Bid  :          $bestBid        Size: $bestBidSize"
        echo "          Ask  :          $bestAsk        Size: $bestAskSize"
        echo " "
        echo "============================KuCoin============================="

        if (( $(echo "$price_point <= $sell_point" |bc -l) )) && [[ $above -eq 0 ]]; then
                echo "It's at/below $sell_point .. notifying"
                MESSAGE="${HODL} - ${PAIR} is AT/BELOW ${sell_point} on KuCoin. ACT FAST!"
                echo "$MESSAGE"
                echo "$MESSAGE" | ssmtp "$notification_email"
                sell_point=`echo "$sell_point - $spread" | bc`
        elif (( $(echo "$price_point >= $sell_point" |bc -l) )) && [[ $above -eq 1 ]]; then
                echo "It's at/above $sell_point .. notifying"
                MESSAGE="${HODL} - ${PAIR} is AT/ABOVE ${sell_point} on KuCoin. ACT FAST!"
                echo "$MESSAGE"
                echo "$MESSAGE" | ssmtp "$notification_email"
                sell_point=`echo "$sell_point + $spread" | bc`
        else
                echo "Meh. Notch yet"
        fi
        sleep 90
done

