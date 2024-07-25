/*
 * Copyright (c) 2016, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.TXT file in the repo root  or https://opensource.org/licenses/BSD-3-Clause
 */

package io.ballerinax.salesforce;

import org.cometd.bayeux.Message;
import org.cometd.bayeux.client.ClientSessionChannel;

import java.io.PrintStream;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Commandline logger for Long polling.
 */
public class LoggingListener implements ClientSessionChannel.MessageListener {
    private static final PrintStream console;
    private final boolean logSuccess;
    private final boolean logFailure;

    public LoggingListener() {
        this.logSuccess = true;
        this.logFailure = true;
    }

    public LoggingListener(boolean logSuccess, boolean logFailure) {
        this.logSuccess = logSuccess;
        this.logFailure = logFailure;
    }

    @Override
    public void onMessage(ClientSessionChannel clientSessionChannel, Message message) {
        if (logSuccess && message.isSuccessful()) {
            console.println(">>>>");
            printPrefix();
            console.println("Success:[" + clientSessionChannel.getId() + "]");
            console.println(message);
            console.println("<<<<");
        }

        if (logFailure && !message.isSuccessful()) {
            console.println(">>>>");
            printPrefix();
            console.println("Failure:[" + clientSessionChannel.getId() + "]");
            console.println(message);
            console.println("<<<<");
        }
    }

    private void printPrefix() {
        console.print("[" + timeNow() + "] ");
    }

    private String timeNow() {
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
        Date now = new Date();
        return dateFormat.format(now);
    }
    static {
        console = System.out;
    }
}
