package org.munin.plugin.jmx;
import java.lang.management.ManagementFactory.*;
import javax.management.MBeanServerConnection;
import java.lang.management.MemoryPoolMXBean;
import java.io.FileNotFoundException;
import java.io.IOException;
public class MemorythresholdUsageCount {

    public static void main(String args[])throws FileNotFoundException, IOException {
        String[] connectionInfo= ConfReader.GetConnectionInfo();

        if (args.length == 1) {
            if (args[0].equals("config")) {
                System.out.println("graph_title JVM (port " + connectionInfo[1] + ") MemorythresholdUsageCount\n" +
                        "graph_vlabel count\n" +
			"graph_category " + connectionInfo[2] + "\n" +
                        "graph_info Returns the number of times that the memory usage has crossed the usage threshold.\n" +
                        "TenuredGen.label TenuredGen\n" +
                        "TenuredGen.info UsageThresholdCount for Tenured Gen \n" +
                        "PermGen.label PermGen\n" +
                        "PermGen.info UsageThresholdCount for Perm Gen\n" 
                       );
            }
         else {
            try {
                MBeanServerConnection connection = BasicMBeanConnection.get();
                GetUsageThresholdCount collector = new GetUsageThresholdCount(connection);
                String[] temp = collector.GC();

                System.out.println("TenuredGen.value " + temp[0]);
                System.out.println("PermGen.value " + temp[1]);

            } catch (Exception e) {
                System.out.print(e);
            }
        }
    }
}
}