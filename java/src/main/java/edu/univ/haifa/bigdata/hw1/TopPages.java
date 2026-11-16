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
 * Task 4 (top-K, two chained jobs): the K most viewed pages per Wikipedia language,
 * desktop + mobile, all hours. Excludes "-", "Main_Page" and "Special:" pages.
 * Output: lang, rank, title, views.
 * Usage: top-pages [-D hw1.k=10] [-D hw1.langs=en,de] &lt;in&gt; &lt;out&gt;
 */
public class TopPages extends Configured implements Tool {

    /** Job 1 mapper: emits ("lang\ttitle", views). */
    public static class TitleMapper extends Mapper<LongWritable, Text, Text, LongWritable> {
        @Override
        protected void map(LongWritable offset, Text line, Context ctx) throws IOException, InterruptedException {
            // TODO
        }
    }

    /** Job 2 mapper: reads job 1 output and keeps a top-K per language in memory. */
    public static class TopKMapper extends Mapper<LongWritable, Text, Text, Text> {
        @Override
        protected void map(LongWritable offset, Text line, Context ctx) {
            // TODO: update this language's bounded heap (java.util.PriorityQueue).
        }

        @Override
        protected void cleanup(Context ctx) throws IOException, InterruptedException {
            // TODO: emit each language's local top K.
        }
    }

    /** Job 2 reducer: merges the local top-K lists of one language. */
    public static class TopKReducer extends Reducer<Text, Text, Text, Text> {
        @Override
        protected void reduce(Text lang, Iterable<Text> values, Context ctx) throws IOException, InterruptedException {
            // TODO: emit (lang, "rank\ttitle\tviews"), best first; break ties by title.
        }
    }

    @Override
    public int run(String[] args) throws Exception {
        // TODO: run job 1 into a temporary directory, then job 2 on its output.
        return 1;
    }

    public static void main(String[] args) throws Exception {
        System.exit(ToolRunner.run(new TopPages(), args));
    }
}
