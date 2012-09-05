### Latches ###

Sometimes waiting for an element or text on the page is insufficient for synchronization purposes. At that point, you need to look at a _latch_. There are examples floating around in various languages, but I had not yet seen one using Flex. So here it is, in all its flex-ish goodness. But the write-up for it is at http://element34.ca/php-webdriver/flex-latches.

To launch the site..

    cd site
    python -m SimpleHTTPServer
    
which will start a webserver on port 8000.