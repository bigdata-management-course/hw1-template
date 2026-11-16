package edu.univ.haifa.bigdata.hw1;

import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

import java.io.IOException;

/**
 * Task 2 (filtering + summarization): desktop and mobile views per Wikipedia language and hour.
 * Output: lang, hour, desktop, mobile, mobile %.
 * Usage: hourly-profile [-D hw1.langs=en,de,he] &lt;in&gt; &lt;out&gt;   (no hw1.langs = all languages)
 */
public class HourlyProfile extends Configured implements Tool {

    public static class HourMapper extends Mapper<LongWritable, Text, Text, ViewPair> {
        @Override
        protected void setup(Context ctx) throws IOException {
            // TODO: read hw1.langs (Configuration.getTrimmedStringCollection).
            // TODO: get the hour from the input file name: ((FileSplit) ctx.getInputSplit()).getPath(), Pageview.hourOf().
        }

        @Override
        protected void map(LongWritable offset, Text line, Context ctx) throws IOException, InterruptedException {
            // TODO: keep Wikipedia languages only (Pageview.language()), apply the hw1.langs filter,
            // TODO: emit ("lang\thour", ViewPair) with the views in the desktop or the mobile slot.
        }
    }

    public static class PairSumReducer extends Reducer<Text, ViewPair, Text, ViewPair> {
        @Override
        protected void reduce(Text key, Iterable<ViewPair> values, Context ctx) throws IOException, InterruptedException {
            // TODO: sum desktop and mobile separately. Can this class also be the combiner?
        }
    }

    @Override
    public int run(String[] args) throws Exception {
        // TODO: configure and submit the job (see ProjectViews.run).
        return 1;
    }

    public static void main(String[] args) throws Exception {
        System.exit(ToolRunner.run(new HourlyProfile(), args));
    }
}
