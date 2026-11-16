package edu.univ.haifa.bigdata.hw1;

import org.apache.hadoop.io.Writable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

/** Desktop and mobile view counts, used as the Task 2 map output value. */
public class ViewPair implements Writable {

    private long desktop;
    private long mobile;

    public void set(long desktop, long mobile) {
        this.desktop = desktop;
        this.mobile = mobile;
    }

    public long getDesktop() {
        return desktop;
    }

    public long getMobile() {
        return mobile;
    }

    @Override
    public void write(DataOutput out) throws IOException {
        // TODO: serialize both fields.
    }

    @Override
    public void readFields(DataInput in) throws IOException {
        // TODO: read both fields, in the same order as write().
    }

    @Override
    public String toString() {
        // TODO: "desktop<TAB>mobile<TAB>mobile%" with one decimal, e.g. "120\t380\t76.0".
        return "";
    }
}
