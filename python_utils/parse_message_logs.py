import sys
from collections import defaultdict
import matplotlib.pyplot as plt

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
    
    # Calculate averages per epoch, starting from epoch 2
    for epoch in sorted(stats.keys()):
        if epoch == 0 or epoch == 1:
            continue
        total_msgs = sum(sum(msgs) for msgs in stats[epoch].values())
        num_partitions = len(stats[epoch])
        avg = total_msgs / num_partitions if num_partitions > 0 else 0
        
        epochs.append(epoch)
        avg_messages.append(avg)
    
    return epochs, avg_messages

def plot_comparison(file1, file2, label1='Baseline', label2='SendOnChange'):
    epochs1, avg1 = parse_log(file1)
    epochs2, avg2 = parse_log(file2)
    
    # Create plot
    plt.figure(figsize=(10, 6))
    
    # Plot both lines
    plt.plot(epochs1, avg1, linewidth=2, label=label1)
    plt.plot(epochs2, avg2, linewidth=2, label=label2)
    
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