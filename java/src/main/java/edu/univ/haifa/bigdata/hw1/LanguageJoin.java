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
 * Task 3 (reduce-side join): Task 1 totals (fact) LEFT OUTER JOIN languages.tsv (dimension) on the language code.
 * Output: lang, name (UNKNOWN if not in the dimension), total views (desktop + mobile).
 * Usage: language-join &lt;task1-out&gt; &lt;languages.tsv&gt; &lt;out&gt;
 */
public class LanguageJoin extends Configured implements Tool {

    public enum Counter { UNMATCHED_LANGUAGES, LANGUAGES_WITHOUT_VIEWS }

    /** Task 1 output line "project\tviews". */
    public static class FactMapper extends Mapper<LongWritable, Text, Text, Text> {
        @Override
        protected void map(LongWritable offset, Text line, Context ctx) throws IOException, InterruptedException {
            // TODO: map the project to its language (Pageview.languageOf); emit (lang, tagged views).
        }
    }

    /** languages.tsv line "code\tname"; lines starting with # are comments. */
    public static class DimMapper extends Mapper<LongWritable, Text, Text, Text> {
        @Override
        protected void map(LongWritable offset, Text line, Context ctx) throws IOException, InterruptedException {
            // TODO: emit (code, tagged name).
        }
    }

    public static class JoinReducer extends Reducer<Text, Text, Text, Text> {
        @Override
        protected void reduce(Text lang, Iterable<Text> values, Context ctx) throws IOException, InterruptedException {
            // TODO: sum the fact values, remember the name; emit (lang, "name\tviews").
            // TODO: languages without a name become UNKNOWN; count both kinds of mismatch with Counter.
        }
    }

    @Override
    public int run(String[] args) throws Exception {
        // TODO: one input per mapper with MultipleInputs.addInputPath.
        return 1;
    }

    public static void main(String[] args) throws Exception {
        System.exit(ToolRunner.run(new LanguageJoin(), args));
    }
}
