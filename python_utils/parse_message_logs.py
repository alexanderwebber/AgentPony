import sys
from collections import defaultdict
import matplotlib.pyplot as plt
import numpy as np

def parse_log(filename):
    stats = defaultdict(lambda: defaultdict(list))
    
    with open(filename, 'r') as f:
        for line in f:
            if line.startswith('ID|'):
                parts = line.strip().split('|')
                partition = int(parts[1])
                epoch = int(parts[2])
                messages = int(parts[3])
                stats[epoch][partition].append(messages)
    
    epochs = []
    avg_messages = []
    std_errors = []
    
    # Calculate averages and standard errors per epoch, starting from epoch 2
    for epoch in sorted(stats.keys()):
        if epoch == 0 or epoch == 1:
            continue
        
        # Collect all messages for this epoch across partitions
        all_msgs = []
        for msgs in stats[epoch].values():
            all_msgs.extend(msgs)
        
        if len(all_msgs) > 0:
            avg = np.mean(all_msgs)
            # Standard error of the mean
            std_err = np.std(all_msgs, ddof=1) / np.sqrt(len(all_msgs))
        else:
            avg = 0
            std_err = 0
        
        epochs.append(epoch)
        avg_messages.append(avg)
        std_errors.append(std_err)
    
    return epochs, avg_messages, std_errors

def plot_comparison(file1, file2, label1='Baseline', label2='SendOnChange'):
    epochs1, avg1, err1 = parse_log(file1)
    epochs2, avg2, err2 = parse_log(file2)
    
    # Create plot
    plt.figure(figsize=(10, 6))
    
    # Plot both lines with error bars - reduced error bar frequency and styling
    errorevery = 5  # Show error bars every 5 epochs
    plt.errorbar(epochs1, avg1, yerr=err1, linewidth=2, label=label1, 
                 errorevery=errorevery, capsize=4, capthick=1.5, 
                 elinewidth=1.5, alpha=0.8)
    plt.errorbar(epochs2, avg2, yerr=err2, linewidth=2, label=label2, 
                 errorevery=errorevery, capsize=4, capthick=1.5, 
                 elinewidth=1.5, alpha=0.8)
    
    plt.xlabel('Epoch', fontsize=12)
    plt.ylabel('Average Messages per Partition', fontsize=12)
    plt.title('Game of Life - Send on Change', fontsize=14)
    plt.legend(fontsize=11)
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('message_stats_comparison.png', dpi=300, bbox_inches='tight')
    print(f"\nComparison plot saved to message_stats_comparison.png")
    plt.show()

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python parse_message_logs.py <baseline_log> <sendonchange_log>")
        sys.exit(1)
    
    plot_comparison(sys.argv[1], sys.argv[2])