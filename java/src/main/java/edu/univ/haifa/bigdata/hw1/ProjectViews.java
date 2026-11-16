package edu.univ.haifa.bigdata.hw1;

import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

import java.io.IOException;

/**
 * Task 1 (summarization): total views per project code over all input hours.
 * Usage: project-views [-D hw1.combiner=false] [-D mapreduce.job.reduces=N] &lt;in&gt; &lt;out&gt;
 */
public class ProjectViews extends Configured implements Tool {

    public static class ViewsMapper extends Mapper<LongWritable, Text, Text, LongWritable> {
        @Override
        protected void map(LongWritable offset, Text line, Context ctx) throws IOException, InterruptedException {
            // TODO: parse the line with Pageview.parse(); count malformed lines with Pageview.Counter.MALFORMED.
            // TODO: emit (project, views).
        }
    }

    public static class SumReducer extends Reducer<Text, LongWritable, Text, LongWritable> {
        @Override
        protected void reduce(Text key, Iterable<LongWritable> values, Context ctx) throws IOException, InterruptedException {
            // TODO: emit (key, sum of values).
        }
    }

    @Override
    public int run(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("usage: project-views [-D hw1.combiner=false] <in> <out>");
            return 2;
        }
        Job job = Job.getInstance(getConf(), "hw1 project-views");
        job.setJarByClass(ProjectViews.class);
        job.setMapperClass(ViewsMapper.class);
        // TODO: set a combiner unless -D hw1.combiner=false (read it with getConf().getBoolean).
        job.setReducerClass(SumReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(LongWritable.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        return job.waitForCompletion(true) ? 0 : 1;
    }

    public static void main(String[] args) throws Exception {
        System.exit(ToolRunner.run(new ProjectViews(), args));
    }
}
